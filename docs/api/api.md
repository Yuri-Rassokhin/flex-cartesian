```mermaid
flowchart TB
    classDef layer fill:#ffffff,stroke:#2c3e50,stroke-width:2px;
    classDef ghost fill:transparent,stroke:transparent,color:transparent;

    subgraph Analyzers ["Analyzers"]
        direction LR
        gA1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ M["<b>Morris</b><br/>def initialize<br/>def sensitivity<br/>def output"] ~~~ gA2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    subgraph Core ["Core Components"]
        direction LR
        DS["<b>Data Sources</b><br/>def data"] ~~~ UT["<b>Utilities</b><br/>def size<br/>def to_a<br/>def vector_to"] ~~~ FN["<b>Functions</b><br/>def func"] ~~~ IT["<b>Iterators</b><br/>def cartesian"] ~~~ IO["<b>Input / Output</b><br/>def import<br/>def export<br/>def visualize..."]
    end

    subgraph Cond ["Conditions"]
        direction LR
        gC1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ C["<b>Conditions</b><br/>def cond"] ~~~ gC2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    subgraph Params ["Parameter Space"]
        direction LR
        gP1["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost ~~~ PS["<b>Parameter Space</b><br/>def initialize<br/>valid?<br/>levels<br/>dimensionality..."] ~~~ gP2["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]:::ghost
    end

    Analyzers ~~~ Core
    Core ~~~ Cond
    Cond ~~~ Params

    class Analyzers,Core,Cond,Params layer;
```
