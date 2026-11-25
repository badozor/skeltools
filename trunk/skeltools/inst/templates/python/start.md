Python environment specific to this project (`myenv/`, with its own Jupyter
kernel), from R: `skeltools::create_venv()`, or from a terminal:

```bash
path_for_python/python -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
python -m ipykernel install --sys-prefix --name myenv --display-name "myenv ({{name}})"
```
