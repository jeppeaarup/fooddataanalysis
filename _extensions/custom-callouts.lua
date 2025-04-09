-- Global state to track counters and book information
local exercise_counters = {}  -- Exercise counters per chapter
local example_counters = {}  -- Example counters per chapter
local current_chapter = 1  -- Track current chapter number
local book_info = {
  is_book = false,
  is_html_book = false,
  processed_file = "",
}

-- Utility function to write warning messages
local function warn(message)
  io.stderr:write("\27[33mWARN: " .. message .. "\27[0m\n")
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
  end
end

-- Process exercise, task, and example divs
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
    
    -- Extract title from first header
    if div.content[1] and div.content[1].t == "Header" then
      exercise_title = pandoc.utils.stringify(div.content[1])
      div.content:remove(1)
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

  -- Process example callouts
  if div.classes:includes("callout-example") then
    -- Initialize counter for this chapter if it doesn't exist
    if not example_counters[current_chapter] then
      example_counters[current_chapter] = 0
    end
    example_counters[current_chapter] = example_counters[current_chapter] + 1
    
    local example_number = string.format("%d.%d", current_chapter, example_counters[current_chapter])
    local example_title = nil
    
    -- Extract title from first header
    if div.content[1] and div.content[1].t == "Header" then
      example_title = pandoc.utils.stringify(div.content[1])
      div.content:remove(1)
    end
    
    -- Create example callout with number and title
    local final_title = "Example " .. example_number
    if example_title then
      final_title = final_title .. " - " .. example_title
    end
    
    return quarto.Callout({
      type = "example",
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

-- Return the filter with the correct execution order
return {
  { Meta = function(meta)
      init_book_info(meta)
    end 
  },
  { Div = Div }
}