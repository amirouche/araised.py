# araised

Static analysis tool that answers: *what exceptions can this function raise?*

Analyses explicit `raise` statements and common stdlib callables (`dict[key]`,
`open()`, `json.loads()`, etc.) using Pyright for type inference. Propagates
through same-module and cross-file call chains with cycle detection.

## Installation

```
pip install araised
```

To install the latest development version directly from the `dev` branch:

```
uv tool install git+https://github.com/amirouche/raises.py@dev
```

Requires [Pyright](https://github.com/microsoft/pyright) (`pip install pyright`),
which is pulled in automatically as a dependency.

## CLI

```
araised module.path:callable [module.path:callable ...]
```

The target is `module.path:callable`, where callable is a bare function name or
`ClassName.method_name`.

```
$ araised myapp.db:connect
myapp.db:connect
  builtins.KeyError        [dict.__getitem__, step 1]
  builtins.ValueError      [explicit raise, step 2]
  builtins.OSError         [builtins.open, step 1, via myapp.db:connect → myapp.db:_open_file]
```

Each line shows the exception, where it comes from, the analysis step, and the
call chain (`via`) if it was propagated from a callee.

Multiple targets can be passed in one invocation:

```
$ araised myapp.db:connect myapp.db:disconnect
```

## Programmatic API

```python
import araised

entries = araised.analyse('myapp.db:connect')
for e in entries:
    print(e.exception, e.source, e.step, e.via)
```

`analyse` returns a list of `RaisesEntry` namedtuples:

| Field | Type | Description |
|-------|------|-------------|
| `exception` | `str` | Fully-qualified exception name, e.g. `builtins.KeyError` |
| `source` | `str` | What triggered it, e.g. `dict.__getitem__` or `explicit raise` |
| `step` | `int` | `1` = inferred from type, `2` = explicit `raise` statement |
| `via` | `tuple[str, ...]` | Call chain leading to this exception (empty for direct) |

**Optional parameters:**

```python
araised.analyse(
    'myapp.db:connect',
    max_depth=3,        # max cross-file hops (default 3, 0 = no cross-file)
    max_union_width=3,  # max union members for dynamic dispatch (default 3)
)
```

## Emacs

Load `araised.el` and call `araised-at-point` with point inside any Python function
or method. It infers the target from the current file and def automatically, then
shows results in a `*araised*` buffer.

```elisp
(load "/path/to/araised.el")

;; optional keybinding
(add-hook 'python-mode-hook
          (lambda () (local-set-key (kbd "C-c r") #'araised-at-point)))
```

With point inside a function, `M-x araised-at-point` (or `C-c r`) prompts:

```
araised target: myapp.db:connect
```

Edit the target if needed, then press `RET`. Results appear in `*araised*`.
