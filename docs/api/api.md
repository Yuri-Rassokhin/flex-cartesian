```mermaid
flowchart TD
    subgraph Analyzers ["Analyzers"]
        M[Morris<br/>def initialize...<br/>def sensitivity...<br/>def output...]
    end

    subgraph MidTier ["Core Components"]
        direction LR
        DS[Data Sources]
        UT[Utilities]
        FN[Functions]
        IT[Iterators]
        IO[Input / Output]
    end

    subgraph Cond ["Conditions"]
        C[def cond...]
    end

    subgraph Params ["Parameter Space"]
        PS[def initialize...<br/>valid?<br/>levels<br/>dimensionality...]
    end

    Analyzers --> MidTier
    MidTier --> Cond
    Cond --> Params
