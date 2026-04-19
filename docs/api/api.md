<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FlexCartesian Logical Component Stack</title>
    <style>
        :root {
            --border-color: #2c3e50;
            --bg-main: #f8f9fa;
            --bg-panel: #ffffff;
            --code-bg: #f1f3f5;
            --text-main: #333;
            --code-text: #e83e8c;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-main);
            color: var(--text-main);
            padding: 40px 20px;
            line-height: 1.5;
        }

        .stack-container {
            display: flex;
            flex-direction: column;
            gap: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }

        .layer {
            border: 2px solid var(--border-color);
            background-color: var(--bg-panel);
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }

        .layer-title {
            text-align: center;
            font-weight: 700;
            font-size: 1.2rem;
            margin-bottom: 20px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        /* Средний слой из 5 колонок */
        .middle-tier {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 15px;
        }

        .module {
            border: 1px solid var(--border-color);
            padding: 15px;
            background-color: var(--bg-panel);
            display: flex;
            flex-direction: column;
        }

        .module-title {
            text-align: center;
            font-weight: 600;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
        }

        .sub-module {
            border: 1px solid #7f8c8d;
            margin: 15px auto 0 auto;
            padding: 15px;
            max-width: 300px;
        }

        .sub-module-title {
            text-align: center;
            font-weight: bold;
            margin-bottom: 10px;
        }

        pre, code {
            font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;
            font-size: 0.85rem;
            background-color: var(--code-bg);
            padding: 8px 10px;
            border-radius: 4px;
            white-space: pre-wrap;
            margin-bottom: 10px;
        }

        .attributes-list {
            text-align: center;
            margin-bottom: 20px;
            font-family: "SFMono-Regular", Consolas, monospace;
            font-size: 0.9rem;
        }

        .param-space-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
        }

        .param-space-methods {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }

        .code-block-no-bg {
            background: none;
            padding: 0;
            margin: 0;
            margin-bottom: 10px;
            display: block;
        }

    </style>
</head>
<body>

    <div class="stack-container">
        
        <div class="layer">
            <div class="layer-title">Analyzers</div>
            <div class="attributes-list">
                space, names, levels, name, description, url, complexity, category
            </div>
            
            <div class="sub-module">
                <div class="sub-module-title">Morris</div>
                <pre>def initialize
  space,
  trajectories:,
  step: 1,
  seed: nil</pre>
                <pre>def sensitivity
  func:</pre>
                <pre>def output
  func:,
  categorize: true,
  recommend: true,
  **opts</pre>
            </div>
        </div>

        <div class="middle-tier">
            <div class="module">
                <div class="module-title">Data Sources</div>
                <pre>def data
  command,
  vector: nil,
  target: nil</pre>
            </div>

            <div class="module">
                <div class="module-title">Utilities</div>
                <pre>def size</pre>
                <pre>def to_a
  vector = nil,
  limit: nil</pre>
                <pre>def vector_to
  vector,
  type</pre>
            </div>

            <div class="module">
                <div class="module-title">Functions</div>
                <pre>def func
  command = :print,
  name = nil,
  hide: false,
  progress: false,
  title: "calculating functions",
  order: nil,
  &block</pre>
            </div>

            <div class="module">
                <div class="module-title">Iterators</div>
                <pre>def cartesian
  dims = nil,
  lazy: false,
  progress: false,
  title: "Traversing space"</pre>
            </div>

            <div class="module">
                <div class="module-title">Input / Output</div>
                <pre>def output
  function: nil,
  separator: " | ",
  colorize: false,
  align: true,
  format: :plain,
  limit: nil,
  file: nil</pre>
                <pre>def import
  path,
  format: :json</pre>
                <pre>def export
  path,
  format: :json</pre>
                <pre>def visualize
  x:,
  y:,
  func:,
  output: nil,
  text: :dark,
  show_legend: false,
  show_z_title: true,
  show_grid: true,
  equal_axes: true,
  start_at_zero: true,
  show_plot_title: false,
  bg_color: 'transparent',
  font_color: nil,
  grid_color: nil,
  colorscale: 'Bluered'</pre>
            </div>
        </div>

        <div class="layer">
            <div class="layer-title">Conditions</div>
            <div style="display: flex; justify-content: center;">
                <pre style="min-width: 300px;">def cond
  command = :print,
  index: nil,
  &block</pre>
            </div>
        </div>

        <div class="layer">
            <div class="layer-title">Parameter Space</div>
            <div class="param-space-grid">
                <div>
                    <pre>def initialize
  dims = nil,
  path: nil,
  format: :json,
  source: nil,
  uri: nil,
  dimensions: nil,
  separator: ','</pre>
                </div>
                <div class="param-space-methods">
                    <pre class="code-block-no-bg">valid?(vector)</pre>
                    <pre class="code-block-no-bg">levels</pre>
                    <pre class="code-block-no-bg">function_results</pre>
                    <pre class="code-block-no-bg">dimensionality</pre>
                    <pre class="code-block-no-bg">dimensions</pre>
                    <pre class="code-block-no-bg">raw_size</pre>
                    <pre class="code-block-no-bg">names</pre>
                    <pre class="code-block-no-bg">function(vector, substitute = 0)</pre>
                </div>
            </div>
        </div>

    </div>

</body>
</html>
