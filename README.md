# Teaching material for Food Data Analysis
This repo contains a Quarto-based site containing teaching material for the Food Data Analysis course at UCPH.

## Notes for updating 

### File structure
The chapters are structured using a folder for each week and every folder contains the following:

- A `week_x.qmd` document containing the introduction to the chapter.
- A `.qmd` file for each section contained in the section.
- Data and images used in each chapter.

### Custom callouts
The document uses a custom LUA-filter for creating callouts used for tasks and exercises. Both are styled in the `style.scss` sheet.

#### Exercise callouts
To create a **reference-able** exercise callout use the following setup:

```
::: {#ex-my-exercise}
::: {.callout-exercise}

*Exercise goes here*

:::
:::
```

The outer div environment is used to create the cross-reference anchor and the inner div is used for styling purposes.
This is only a temporay fix until Quarto updates to a more robust system for custom callouts. 

The callout can then be referenced using `@ex-my-exercise`. Be aware that the reference must contain `ex-` like in the example above.

If the exercise does not need to be cross-referenced then the outer div is not needed.

#### Task callouts
To draw attention to a list of tasks within (or outside of) an exercise div a task callout can be used:

```
::: {.callout-task}

1. Do this
2. Then do this
3. Why do you think that is?

:::
```

Note that this callout cannot be cross-referenced and thus an outer div environment is not needed. 
