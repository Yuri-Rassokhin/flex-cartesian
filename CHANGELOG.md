# Changelog

## 2.1.0 - 2026
## Fixed
- More concise semantics of multiple formatting flags
## Added
- Method .fold for the transformation of space functions against folded dimensions
- .fold supports three folding modes for mult-dimensional folding
- Method .where for the slicing of a space

## 2.0.1 - 2026-06-20
## Added
- Dynamic dimensions (adding/removing)
- Interactive HTML heatmaps
- Connecting parameter space to external data sources
- Enhanced and more robust Morris analysis

## 2.0.0.beta - 2026-06-17
### Fixed
- Performance scalability on large spaces

## 1.3.1 - 2025-09-03
### Fixed
- CSV format expects separator to be one of ";" or "," otherwise enforces ";"

## 1.3.0 - 2025-08-19
### Added
- .func accepts flag order:

## 1.2.2 - 2025-07-28
### Added
- .dimensions functionality extended to more granular formatting

## 1.2.1 - 2025-07-28
### Fixed
- When adding function, check if its namesake exists

## 1.2 - 2025-07-23
## Added
- Optional progress bar to the function command :run

## 1.1 - 2025-07=22
### Fixed
- Dependencies

## 1.0 - 2025-07-14
### Added
- Optional flad for hiding function from output

### Fixed
- Simplified default parameters
- Unified umbrella method for handling functions
- Initialization directly from file of dimensions

## 0.2 - 2025-07-12
### Added
- Logical conditions on Cartesian space

## 0.1.9 - 2025-07-08
### Fixed
- Documentation

### Added
- Unified methods for import and export
- JSON and YAML can be imported, not only exported
- Functions can be removed
- Minor changes in default values of named parameters

## 0.1.8 - 2025-07-07
### Fixed
- Documentation

## 0.1.7 - 2025-07-07
### Added
- Support for calculated functions on dimensions via `add_function(name, &block)`
- Calculated functions now show up in `.output`

