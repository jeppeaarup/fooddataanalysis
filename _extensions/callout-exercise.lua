-- Global state to track exercises and book information
local exercises = {}  -- Store exercise data
local exercise_counters = {}  -- Exercise counters per chapter
local seen_ids = {}  -- Track seen IDs
local current_chapter = 1  -- Track current chapter number
local book_info = {
  is_book = false,
  is_html_book = false,
  processed_file = "",
  xref_file = "._exercise_xref.json",
  is_first_file = true,
  is_last_file = false
}

-- Utility function to write warning messages
local function warn(message)
  io.stderr:write("\27[33mWARN: " .. message .. "\27[0m\n")
end

-- Read cross-references from file
local function read_xref(meta)
  local file = io.open(book_info.xref_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    if content then
      exercises = quarto.json.decode(content)
    end
  end
  return meta
end

-- Write cross-references to file
local function write_xref(meta)
  local file = io.open(book_info.xref_file, "w")
  if file then
    file:write(quarto.json.encode(exercises))
    file:close()
  end
  
  -- Clean up old references if this is the last file
  if book_info.is_last_file then
    for id, exercise in pairs(exercises) do
      if not exercise.new then
        exercises[id] = nil
      end
    end
  end
  return meta
end

-- Function to find the chapter number from book metadata
local function get_chapter_number(book, current_file)
  local chapter_count = 0
  
  -- Function to get just the filename without path and normalize the extension
  local function get_base_filename(path)
    local name = path:match("([^/]+)$") or path
    name = name:gsub("%.qmd$", ""):gsub("%.html$", "")
    return name
  end
  
  local current_base = get_base_filename(current_file)
  
  if book.chapters then
    for _, chapter in ipairs(book.chapters) do
      if chapter.part then
        if type(chapter.chapters) == "table" then
          for _, subchapter in ipairs(chapter.chapters) do
            local file = pandoc.utils.stringify(subchapter)
            local file_base = get_base_filename(file)
            chapter_count = chapter_count + 1
            if file_base == current_base then
              return chapter_count
            end
          end
        end
      elseif type(chapter) == "string" then
        local file = pandoc.utils.stringify(chapter)
        local file_base = get_base_filename(file)
        if file_base ~= "index" then
          chapter_count = chapter_count + 1
          if file_base == current_base then
            return chapter_count
          end
        end
      end
    end
  end
  return 1
end

-- Initialize book information and get chapter number
local function init_book_info(meta)
  local processed_file = pandoc.path.split_extension(PANDOC_STATE.output_file)
  book_info.is_book = meta.book ~= nil
  book_info.is_html_book = meta.book ~= nil and not quarto.doc.is_format("pdf")
  book_info.processed_file = processed_file
  
  if book_info.is_book then
    current_chapter = get_chapter_number(meta.book, processed_file)
    
    if book_info.is_html_book then
      book_info.xref_file = "._exercise_htmlbook_xref.json"
    else
      book_info.xref_file = "._exercise_pdfbook_xref.json"
    end
  else
    book_info.xref_file = "._" .. processed_file .. "_exercise_xref.json"
  end
end

-- Process exercise and task divs
function Div(div)
  -- Process exercise callouts
  if div.classes:includes("callout-exercise") then
    -- Initialize counter for this chapter if it doesn't exist
    if not exercise_counters[current_chapter] then
      exercise_counters[current_chapter] = 0
    end
    exercise_counters[current_chapter] = exercise_counters[current_chapter] + 1
    
    local exercise_number = string.format("%d.%d", current_chapter, exercise_counters[current_chapter])
    local exercise_title = nil
    
    -- Store exercise information for cross-referencing
    if div.identifier and div.identifier:match("^ex%-") then
      if seen_ids[div.identifier] then
        warn("Duplicate exercise ID found: #" .. div.identifier)
      end
      
      seen_ids[div.identifier] = true
      exercises[div.identifier] = {
        number = exercise_number,
        file = book_info.processed_file,
        new = true,
        type = "exercise",
        chapter = current_chapter
      }
      
      -- Extract title from first header
      if div.content[1] and div.content[1].t == "Header" then
        exercise_title = pandoc.utils.stringify(div.content[1])
        div.content:remove(1)
      end
    end
    
    -- Create exercise callout with number and title
    local final_title = "Exercise " .. exercise_number
    if exercise_title then
      final_title = final_title .. " - " .. exercise_title
    end
    
    return quarto.Callout({
      type = "exercise",
      content = { div },
      title = final_title,
      id = div.identifier,
      icon = false,
      collapse = false
    })
  end
  
  -- Process task callouts
  if div.classes:includes("callout-task") then
    local task_title = nil
    
    if div.identifier and div.identifier:match("^task%-") then
      if seen_ids[div.identifier] then
        warn("Duplicate task ID found: #" .. div.identifier)
      end
      
      seen_ids[div.identifier] = true
      exercises[div.identifier] = {
        file = book_info.processed_file,
        new = true,
        type = "task"
      }
    end
    
    if div.content[1] and div.content[1].t == "Header" then
      task_title = pandoc.utils.stringify(div.content[1])
      div.content:remove(1)
    end
    
    return quarto.Callout({
      type = "task",
      content = { div },
      title = task_title or "Tasks",
      id = div.identifier,
      icon = false,
      collapse = false
    })
  end
  
  return div
end

-- Replace cross-references
function Cite(cite)
  local id = cite.citations[1].id
  if id:match("^ex%-") or id:match("^task%-") then
    local item = exercises[id]
    
    if item then
      local link_text
      if item.type == "exercise" then
        link_text = "Exercise " .. item.number
      else
        link_text = "Task"
      end
      
      local link_target = "#" .. id
      
      -- Adjust link for HTML book
      if book_info.is_html_book then
        link_target = item.file .. ".html" .. link_target
      end
      
      if quarto.doc.is_format("html") then
        return pandoc.RawInline('html', string.format(
          '<a href="%s">%s</a>', link_target, link_text
        ))
      else
        return pandoc.Link(link_text, link_target)
      end
    else
      warn("Undefined cross-reference: @" .. id)
    end
  end
  return cite
end

-- Return the filter with the correct execution order
return {
  { Meta = function(meta)
      init_book_info(meta)
      return read_xref(meta)
    end 
  },
  { Div = Div },
  { Cite = Cite },
  { Meta = write_xref }
}