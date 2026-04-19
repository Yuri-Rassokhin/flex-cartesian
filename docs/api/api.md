## FlexCartesian Stack

FlexCartesian represents a system using Parametric Behaviour Blueprinting stack, as given below.
Component titles are clickable, and they refer to the description and API of the component.

```mermaid
flowchart TB
    classDef layer fill:#ffffff,stroke:#2c3e50,stroke-width:2px;
    classDef ghost fill:transparent,stroke:transparent,color:transparent;

    subgraph Analyzers ["<b>ANALYZERS</b>"]
        direction LR
        gA1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ M["<b>Morris</b><br/>initialize<br/>sensitivity<br/>output"] ~~~ gA2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    subgraph Core ["<b>BASIC SPACE OPERATIONS</b>"]
        direction LR
        DS["<b>Data Sources</b><br/>data"] ~~~ UT["<b>Utilities</b><br/>size<br/>to_a<br/>vector_to"] ~~~ FN["<b>Functions</b><br/>func"] ~~~ IT["<b>Iterators</b><br/>cartesian"] ~~~ IO["<b>Input / Output</b><br/>output<br/>import<br/>export<br/>visualize"]
    end

    subgraph Cond ["<b>SPACE CONDITIONS</b>"]
        direction LR
        gC1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ C["<b>Conditions</b><br/>cond"] ~~~ gC2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    subgraph Params ["<b>PARAMETER SPACE</b>"]
        direction LR
        gP1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ PS["<b>Parameter Space</b><br/>initialize<br/>valid?<br/>levels<br/>dimensionality"] ~~~ gP2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    Analyzers ~~~ Core
    Core ~~~ Cond
    Cond ~~~ Params

    class Analyzers,Core,Cond,Params layer;
```

## Stack Components

### Parameter Space

Parameter space is a space formed as multi-dimensional Cartesian product of the dimensions represented by discrete dimensional values.

#### Create parameter space

```ruby
def initialize(dims = nil, path: nil, format: :json, source: nil, uri: nil, dimensions: nil, separator: ',')
```

Create dimensions from their description (the space will be empty):

- `dims` hash of dimensions (key) and array of dimensional values (value)
- `path` to the file describing dimensions
- `format` format of the file describing dimensions, either JSON or YAML

Read tabular data source and create dimensions from the specified columns (the space will be empty, but the data source will remain available to link behavioural functions)

- `source` data source type, one of `:xlsx` or `:csv`
- `uri` local path to the data source file
- `dimensions` array of symbolic column names in the data source that will become space dimensions
- `separator` separation symbol in the data source file, either colon or semicolon

#### Check validity of the vector in parameter space

```ruby
def valid?(vector)
```

Check if `vector` has consistent dimensiality, consistent dimensional values, and satisfies conditions in the current space.

#### Get dimensional values

```ruby
def values
```

Return array of arrays of dimensional values.

#### Get dimensiality

```ruby
def dimensiality
```

Return number of dimensions in the current space.

### Space Conditions

Condition is a logical function defined in parameter space.
Condition restricts the space to the subset of vectors that satisfy this condition.
A space can have arbitraty number of conditions, and they apply using logical AND.
This means, conditions restrict the space to the subset that satisfies ALL conditions.

#### Managing Conditions

```ruby
  def cond(command = :print, index: nil, &block)
```

- `command` `:print` prints active space conditions, `:set` adds new conditions as a block, `:unset` removes specific condition by its `index` or all conditions if `index` isn't specified
- `index` identifies condition set in the space; index is assigned automatically, because conditions have no names (unlike functions)
- `block` body of the condition being added; it must return either `true` or `false`


