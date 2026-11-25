Python environment (`myenv/`), from R: `skeltools::create_venv()`, or from a terminal:

```bash
path_for_python/python -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
python -m ipykernel install --user --name myenv
```
