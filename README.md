# Teaching material for Food Data Analysis
This repo contains a Quarto-based site containing teaching material for the Food Data Analysis course at UCPH.

## File structure

### Chapters

The chapters are structured using a folder for each week. These can be found in the `~/chapters/weekx`, and every folder contains the following:

- A `week_x.qmd` document containing the introduction to the chapter.
- A `.qmd` file for each section contained in the section.
- Media, such as images and video used in each chapter.

### Data
The data used in the example codes are either loaded from the [DataAnalysisInFoodScience](https://github.com/mortenarendt/DataAnalysisinFoodScience) package or from the `~/data` folder using the `here` package. Each `.qmd` that uses data has a hidden setup at the top of the document where data is loaded.  

## Custom callouts
The document uses a custom LUA-filter for creating callouts used for tasks and exercises. Both are styled in the `style.scss` sheet.

### Exercise and example callouts
To create a **reference-able** exercise or example callout use the following setup:

#### Exercise callout

````
::: {#ex-my-exercise}
::: {.callout-exercise}

## Exercise title

*Exercise goes here*

:::
:::
````

#### Example callout

````
::: {#exa-my-example}
::: {.callout-example}

## Example title

*Example goes here*

:::
:::
````

The outer div environment is used to create the cross-reference anchor and the inner div is used for styling purposes.
This is only a temporay fix until Quarto updates to a more robust system for custom callouts. 

The callout can then be referenced using `@ex-my-exercise`. Be aware that the reference must contain `ex-` like in the example above.

If the exercise does not need to be cross-referenced then the outer div is not needed.

### Task callouts
To draw attention to a list of tasks within (or outside of) an exercise div a task callout can be used:

````
::: {.callout-task}

1. Do this
2. Then do this
3. Why do you think that is?

:::
````

Note that this callout cannot be cross-referenced and thus an outer div environment is not needed. 