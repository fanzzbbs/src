// Ignore the va_list functions
%ignore AskUsingForm_cv;
%ignore AskUsingForm_c;
%ignore OpenForm_cv;
%ignore OpenForm_c;
%ignore close_form;
%ignore vaskstr;
%ignore strvec_t;
%ignore load_custom_icon;
%ignore vasktext;
%ignore add_menu_item;
%rename (add_menu_item) py_add_menu_item;
%ignore del_menu_item;
%rename (del_menu_item) py_del_menu_item;
%ignore vwarning;

%ignore choose_idasgn;
%rename (choose_idasgn) py_choose_idasgn;

%rename (del_hotkey) py_del_hotkey;
%rename (add_hotkey) py_add_hotkey;

%ignore msg;
%rename (msg) py_msg;

%ignore umsg;
%rename (umsg) py_umsg;

%ignore textctrl_info_t;
%ignore vinfo;
%ignore UI_Callback;
%ignore vnomem;
%ignore vmsg;
%ignore show_wait_box_v;
%ignore askbuttons_cv;
%ignore askfile_cv;
%ignore askyn_cv;
%ignore askyn_v;
%ignore add_custom_viewer_popup_item;
%ignore create_custom_viewer;
%ignore take_database_snapshot;
%ignore restore_database_snapshot;
%ignore destroy_custom_viewer;
%ignore destroy_custom_viewerdestroy_custom_viewer;
%ignore set_custom_viewer_popup_menu;
%ignore set_custom_viewer_handler;
%ignore set_custom_viewer_range;
%ignore is_idaview;
%ignore refresh_custom_viewer;
%ignore set_custom_viewer_handlers;
%ignore get_viewer_name;
// Ignore these string functions. There are trivial replacements in Python.
%ignore addblanks;
%ignore trim;
%ignore skipSpaces;
%ignore stristr;
%ignore set_nav_colorizer;
%rename (set_nav_colorizer) py_set_nav_colorizer;
%rename (call_nav_colorizer) py_call_nav_colorizer;

%ignore get_highlighted_identifier;
%rename (get_highlighted_identifier) py_get_highlighted_identifier;


// CLI
%ignore cli_t;
%ignore install_command_interpreter;
%rename (install_command_interpreter) py_install_command_interpreter;
%ignore remove_command_interpreter;
%rename (remove_command_interpreter) py_remove_command_interpreter;

%ignore action_desc_t::handler;
%ignore action_handler_t;
%ignore register_action;
%rename (register_action) py_register_action;
%ignore unregister_action;
%rename (unregister_action) py_unregister_action;
%ignore attach_dynamic_action_to_popup;
%rename (attach_dynamic_action_to_popup) py_attach_dynamic_action_to_popup;

%include "typemaps.i"

%rename (asktext) py_asktext;
%rename (str2ea)  py_str2ea;
%rename (str2user)  py_str2user;
%ignore process_ui_action;
%rename (process_ui_action) py_process_ui_action;
%ignore execute_sync;
%ignore exec_request_t;
%rename (execute_sync) py_execute_sync;

%ignore ui_request_t;
%ignore execute_ui_requests;
%rename (execute_ui_requests) py_execute_ui_requests;

%ignore timer_t;
%ignore register_timer;
%rename (register_timer) py_register_timer;
%ignore unregister_timer;
%rename (unregister_timer) py_unregister_timer;

// Make askaddr(), askseg(), and asklong() return a
// tuple: (result, value)
%rename (_asklong) asklong;
%rename (_askaddr) askaddr;
%rename (_askseg) askseg;

%ignore qvector<disasm_line_t>::operator==;
%ignore qvector<disasm_line_t>::operator!=;
%ignore qvector<disasm_line_t>::find;
%ignore qvector<disasm_line_t>::has;
%ignore qvector<disasm_line_t>::del;
%ignore qvector<disasm_line_t>::add_unique;

%ignore gen_disasm_text;
%rename (gen_disasm_text) py_gen_disasm_text;

%feature("director") UI_Hooks;

//-------------------------------------------------------------------------
%{
struct py_action_handler_t : public action_handler_t
{
  py_action_handler_t(); // No.
  py_action_handler_t(PyObject *_o)
    : pyah(borref_t(_o)), has_activate(false), has_update(false)
  {
    ref_t act(PyW_TryGetAttrString(pyah.o, "activate"));
    if ( act != NULL && PyCallable_Check(act.o) > 0 )
      has_activate = true;

    ref_t upd(PyW_TryGetAttrString(pyah.o, "update"));
    if ( upd != NULL && PyCallable_Check(upd.o) > 0 )
      has_update = true;
  }
  virtual idaapi ~py_action_handler_t()
  {
    PYW_GIL_GET;
    // NOTE: We need to do the decref _within_ the PYW_GIL_GET scope,
    // and not leave it to the destructor to clean it up, because when
    // ~ref_t() gets called, the GIL will have already been released.
    pyah = ref_t();
  }
  virtual int idaapi activate(action_activation_ctx_t *ctx)
  {
    if ( !has_activate )
      return 0;
    PYW_GIL_GET_AND_REPORT_ERROR;
    newref_t pyctx(SWIG_NewPointerObj(SWIG_as_voidptr(ctx), SWIGTYPE_p_action_activation_ctx_t, 0));
    newref_t pyres(PyObject_CallMethod(pyah.o, (char *)"activate", (char *) "O", pyctx.o));
    return PyErr_Occurred() ? 0 : ((pyres != NULL && PyInt_Check(pyres.o)) ? PyInt_AsLong(pyres.o) : 0);
  }
  virtual action_state_t idaapi update(action_update_ctx_t *ctx)
  {
    if ( !has_update )
      return AST_DISABLE;
    PYW_GIL_GET_AND_REPORT_ERROR;
    newref_t pyctx(SWIG_NewPointerObj(SWIG_as_voidptr(ctx), SWIGTYPE_p_action_update_ctx_t, 0));
    newref_t pyres(PyObject_CallMethod(pyah.o, (char *)"update", (char *) "O", pyctx.o));
    return PyErr_Occurred() ? AST_DISABLE_ALWAYS : ((pyres != NULL && PyInt_Check(pyres.o)) ? action_state_t(PyInt_AsLong(pyres.o)) : AST_DISABLE);
  }
private:
  ref_t pyah;
  bool has_activate;
  bool has_update;
};

typedef std::map<qstring,action_handler_t*> py_action_handlers_t;
static py_action_handlers_t py_action_handlers;

%}

%inline %{
void refresh_lists(void)
{
  Py_BEGIN_ALLOW_THREADS;
  callui(ui_list);
  Py_END_ALLOW_THREADS;
}
%}

# This is for get_cursor()
%apply int *OUTPUT {int *x, int *y};

SWIG_DECLARE_PY_CLINKED_OBJECT(textctrl_info_t)

%{
static void _py_unregister_compiled_form(PyObject *py_form, bool shutdown);
%}

%inline %{
//<inline(py_kernwin)>
//------------------------------------------------------------------------

//------------------------------------------------------------------------
/*
#<pydoc>
def register_timer(interval, callback):
    """
    Register a timer

    @param interval: Interval in milliseconds
    @param callback: A Python callable that takes no parameters and returns an integer.
                     The callback may return:
                     -1   : to unregister the timer
                     >= 0 : the new or same timer interval
    @return: None or a timer object
    """
    pass
#</pydoc>
*/
static PyObject *py_register_timer(int interval, PyObject *py_callback)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();

  if ( py_callback == NULL || !PyCallable_Check(py_callback) )
    Py_RETURN_NONE;

  // An inner class hosting the callback method
  struct tmr_t
  {
    static int idaapi callback(void *ud)
    {
      PYW_GIL_GET;
      py_timer_ctx_t *ctx = (py_timer_ctx_t *)ud;
      newref_t py_result(PyObject_CallFunctionObjArgs(ctx->pycallback, NULL));
      int ret = py_result == NULL ? -1 : PyLong_AsLong(py_result.o);

      // Timer has been unregistered?
      if ( ret == -1 )
      {
        // Free the context
        Py_DECREF(ctx->pycallback);
        delete ctx;
      }
      return ret;
    };
  };

  py_timer_ctx_t *ctx = new py_timer_ctx_t();
  ctx->pycallback = py_callback;
  Py_INCREF(py_callback);
  ctx->timer_id = register_timer(
    interval,
    tmr_t::callback,
    ctx);

  if ( ctx->timer_id == NULL )
  {
    Py_DECREF(py_callback);
    delete ctx;
    Py_RETURN_NONE;
  }
  return PyCObject_FromVoidPtr(ctx, NULL);
}

//------------------------------------------------------------------------
/*
#<pydoc>
def unregister_timer(timer_obj):
    """
    Unregister a timer

    @param timer_obj: a timer object previously returned by a register_timer()
    @return: Boolean
    @note: After the timer has been deleted, the timer_obj will become invalid.
    """
    pass
#</pydoc>
*/
static PyObject *py_unregister_timer(PyObject *py_timerctx)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();

  if ( py_timerctx == NULL || !PyCObject_Check(py_timerctx) )
    Py_RETURN_FALSE;

  py_timer_ctx_t *ctx = (py_timer_ctx_t *) PyCObject_AsVoidPtr(py_timerctx);
  if ( !unregister_timer(ctx->timer_id) )
    Py_RETURN_FALSE;

  Py_DECREF(ctx->pycallback);
  delete ctx;

  Py_RETURN_TRUE;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def choose_idasgn():
    """
    Opens the signature chooser

    @return: None or the selected signature name
    """
    pass
#</pydoc>
*/
static PyObject *py_choose_idasgn()
{
  char *name = choose_idasgn();
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( name == NULL )
  {
    Py_RETURN_NONE;
  }
  else
  {
    PyObject *py_str = PyString_FromString(name);
    qfree(name);
    return py_str;
  }
}

//------------------------------------------------------------------------
/*
#<pydoc>
def get_highlighted_identifier(flags = 0):
    """
    Returns the currently highlighted identifier

    @param flags: reserved (pass 0)
    @return: None or the highlighted identifier
    """
    pass
#</pydoc>
*/
static PyObject *py_get_highlighted_identifier(int flags = 0)
{
  char buf[MAXSTR];
  bool ok = get_highlighted_identifier(buf, sizeof(buf), flags);
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( !ok )
    Py_RETURN_NONE;
  else
    return PyString_FromString(buf);
}

//------------------------------------------------------------------------
static int py_load_custom_icon_fn(const char *filename)
{
  return load_custom_icon(filename);
}

//------------------------------------------------------------------------
static int py_load_custom_icon_data(PyObject *data, const char *format)
{
  Py_ssize_t len;
  char *s;
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( PyString_AsStringAndSize(data, &s, &len) == -1 )
    return 0;
  else
    return load_custom_icon(s, len, format);
}

//------------------------------------------------------------------------
/*
#<pydoc>
def free_custom_icon(icon_id):
    """
    Frees an icon loaded with load_custom_icon()
    """
    pass
#</pydoc>
*/

//-------------------------------------------------------------------------
/*
#<pydoc>
def readsel2(view, p0, p1):
    """
    Read the user selection, and store its information in p0 (from) and p1 (to).

    This can be used as follows:


    >>> p0 = idaapi.twinpos_t()
    p1 = idaapi.twinpos_t()
    view = idaapi.get_current_viewer()
    idaapi.readsel2(view, p0, p1)


    At that point, p0 and p1 hold information for the selection.
    But, the 'at' property of p0 and p1 is not properly typed.
    To specialize it, call #place() on it, passing it the view
    they were retrieved from. Like so:


    >>> place0 = p0.place(view)
    place1 = p1.place(view)


    This will effectively "cast" the place into a specialized type,
    holding proper information, depending on the view type (e.g.,
    disassembly, structures, enums, ...)

    @param view: The view to retrieve the selection for.
    @param p0: Storage for the "from" part of the selection.
    @param p1: Storage for the "to" part of the selection.
    @return: a bool value indicating success.
    """
    pass
#</pydoc>
*/

//------------------------------------------------------------------------
/*
#<pydoc>
def umsg(text):
    """
    Prints text into IDA's Output window

    @param text: text to print
                 Can be Unicode, or string in UTF-8 encoding
    @return: number of bytes printed
    """
    pass
#</pydoc>
*/
static PyObject* py_umsg(PyObject *o)
{
  PyObject* utf8 = NULL;
  if ( PyUnicode_Check(o) )
  {
    utf8 = PyUnicode_AsUTF8String(o);
    o = utf8;
  }
  else if ( !PyString_Check(o) )
  {
    PyErr_SetString(PyExc_TypeError, "A unicode or UTF-8 string expected");
    return NULL;
  }
  int rc;
  Py_BEGIN_ALLOW_THREADS;
  rc = umsg("%s", PyString_AsString(o));
  Py_END_ALLOW_THREADS;
  Py_XDECREF(utf8);
  return PyInt_FromLong(rc);
}

//------------------------------------------------------------------------
/*
#<pydoc>
def msg(text):
    """
    Prints text into IDA's Output window

    @param text: text to print
                 Can be Unicode, or string in local encoding
    @return: number of bytes printed
    """
    pass
#</pydoc>
*/
static PyObject* py_msg(PyObject *o)
{
  if ( PyUnicode_Check(o) )
    return py_umsg(o);

  if ( !PyString_Check(o) )
  {
    PyErr_SetString(PyExc_TypeError, "A string expected");
    return NULL;
  }
  int rc;
  Py_BEGIN_ALLOW_THREADS;
  rc = msg("%s", PyString_AsString(o));
  Py_END_ALLOW_THREADS;
  return PyInt_FromLong(rc);
}

//------------------------------------------------------------------------
/*
#<pydoc>
def asktext(max_text, defval, prompt):
    """
    Asks for a long text

    @param max_text: Maximum text length
    @param defval: The default value
    @param prompt: The prompt value
    @return: None or the entered string
    """
    pass
#</pydoc>
*/
PyObject *py_asktext(int max_text, const char *defval, const char *prompt)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( max_text <= 0 )
    Py_RETURN_NONE;

  char *buf = new char[max_text];
  if ( buf == NULL )
    Py_RETURN_NONE;

  PyObject *py_ret;
  if ( asktext(size_t(max_text), buf, defval, "%s", prompt) != NULL )
  {
    py_ret = PyString_FromString(buf);
  }
  else
  {
    py_ret = Py_None;
    Py_INCREF(py_ret);
  }
  delete [] buf;
  return py_ret;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def str2ea(addr):
    """
    Converts a string express to EA. The expression evaluator may be called as well.

    @return: BADADDR or address value
    """
    pass
#</pydoc>
*/
ea_t py_str2ea(const char *str, ea_t screenEA = BADADDR)
{
  ea_t ea;
  bool ok = str2ea(str, &ea, screenEA);
  return ok ? ea : BADADDR;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def str2user(str):
    """
    Insert C-style escape characters to string

    @return: new string with escape characters inserted
    """
    pass
#</pydoc>
*/
PyObject *py_str2user(const char *str)
{
  qstring qstr(str);
  qstring retstr;
  qstr2user(&retstr, qstr);
  return PyString_FromString(retstr.c_str());
}

//------------------------------------------------------------------------
/*
#<pydoc>
def process_ui_action(name):
    """
    Invokes an IDA UI action by name

    @param name:  action name
    @return: Boolean
    """
    pass
#</pydoc>
*/
static bool py_process_ui_action(const char *name, int flags = 0)
{
  return process_ui_action(name, flags, NULL);
}

//------------------------------------------------------------------------
/*
#<pydoc>
def del_menu_item(menu_ctx):
    """Deprecated. Use detach_menu_item()/unregister_action() instead."""
    pass
#</pydoc>
*/
static bool py_del_menu_item(PyObject *py_ctx)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( !PyCObject_Check(py_ctx) )
    return false;

  py_add_del_menu_item_ctx *ctx = (py_add_del_menu_item_ctx *)PyCObject_AsVoidPtr(py_ctx);

  bool ok = del_menu_item(ctx->menupath.c_str());
  if ( ok )
  {
    Py_DECREF(ctx->cb_data);
    delete ctx;
  }

  return ok;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def del_hotkey(ctx):
    """
    Deletes a previously registered function hotkey

    @param ctx: Hotkey context previously returned by add_hotkey()

    @return: Boolean.
    """
    pass
#</pydoc>
*/
bool py_del_hotkey(PyObject *pyctx)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( !PyCObject_Check(pyctx) )
    return false;

  py_idchotkey_ctx_t *ctx = (py_idchotkey_ctx_t *) PyCObject_AsVoidPtr(pyctx);
  if ( !del_idc_hotkey(ctx->hotkey.c_str()) )
    return false;

  Py_DECREF(ctx->pyfunc);
  delete ctx;
  return true;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def add_hotkey(hotkey, pyfunc):
    """
    Associates a function call with a hotkey.
    Callable pyfunc will be called each time the hotkey is pressed

    @param hotkey: The hotkey
    @param pyfunc: Callable

    @return: Context object on success or None on failure.
    """
    pass
#</pydoc>
*/
PyObject *py_add_hotkey(const char *hotkey, PyObject *pyfunc)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  // Make sure a callable was passed
  if ( !PyCallable_Check(pyfunc) )
    return NULL;

  // Form the function name
  qstring idc_func_name;
  idc_func_name.sprnt("py_hotkeycb_%p", pyfunc);

  // Can add the hotkey?
  if ( add_idc_hotkey(hotkey, idc_func_name.c_str()) == IDCHK_OK ) do
  {
    // Generate global variable name
    qstring idc_gvarname;
    idc_gvarname.sprnt("_g_pyhotkey_ref_%p", pyfunc);

    // Now add the global variable
    idc_value_t *gvar = add_idc_gvar(idc_gvarname.c_str());
    if ( gvar == NULL )
      break;

    // The function body will call a registered IDC function that
    // will take a global variable that wraps a PyCallable as a pvoid
    qstring idc_func;
    idc_func.sprnt("static %s() { %s(%s); }",
      idc_func_name.c_str(),
      S_PYINVOKE0,
      idc_gvarname.c_str());

    // Compile the IDC condition
    char errbuf[MAXSTR];
    if ( !CompileLineEx(idc_func.c_str(), errbuf, sizeof(errbuf)) )
      break;

    // Create new context
    // Define context
    py_idchotkey_ctx_t *ctx = new py_idchotkey_ctx_t();

    // Remember the hotkey
    ctx->hotkey = hotkey;

    // Take reference to the callable
    ctx->pyfunc = pyfunc;
    Py_INCREF(pyfunc);

    // Bind IDC variable w/ the PyCallable
    gvar->set_pvoid(pyfunc);

    // Return the context
    return PyCObject_FromVoidPtr(ctx, NULL);
  } while (false);

  // Cleanup
  del_idc_hotkey(hotkey);
  Py_RETURN_NONE;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def add_menu_item(menupath, name, hotkey, flags, callback, args):
    """Deprecated. Use register_action()/attach_menu_item() instead."""
    pass
#</pydoc>
*/
bool idaapi py_menu_item_callback(void *userdata);
static PyObject *py_add_menu_item(
  const char *menupath,
  const char *name,
  const char *hotkey,
  int flags,
  PyObject *pyfunc,
  PyObject *args)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  bool no_args;

  // No slash in the menu path?
  const char *p = strrchr(menupath, '/');
  if ( p == NULL )
    Py_RETURN_NONE;

  if ( args == Py_None )
  {
    no_args = true;
    args = PyTuple_New(0);
    if ( args == NULL )
      return NULL;
  }
  else if ( !PyTuple_Check(args) )
  {
    PyErr_SetString(PyExc_TypeError, "args must be a tuple or None");
    return NULL;
  }
  else
  {
    no_args = false;
  }

  // Form a tuple holding the function to be called and its arguments
  PyObject *cb_data = Py_BuildValue("(OO)", pyfunc, args);

  // If we created an empty tuple, then we must free it
  if ( no_args )
    Py_DECREF(args);

  // Add the menu item
  bool b = add_menu_item(menupath, name, hotkey, flags, py_menu_item_callback, (void *)cb_data);

  if ( !b )
  {
    Py_XDECREF(cb_data);
    Py_RETURN_NONE;
  }
  // Create a context (for the delete_menu_item())
  py_add_del_menu_item_ctx *ctx = new py_add_del_menu_item_ctx();

  // Form the complete menu path
  ctx->menupath.append(menupath, p - menupath + 1);
  ctx->menupath.append(name);
  // Save callback data
  ctx->cb_data = cb_data;

  // Return context to user
  return PyCObject_FromVoidPtr(ctx, NULL);
}

//------------------------------------------------------------------------
/*
#<pydoc>

MFF_FAST = 0x0000
"""execute code as soon as possible
this mode is ok call ui related functions
that do not query the database."""

MFF_READ = 0x0001
"""execute code only when ida is idle and it is safe to query the database.
this mode is recommended only for code that does not modify the database.
(nb: ida may be in the middle of executing another user request, for example it may be waiting for him to enter values into a modal dialog box)"""

MFF_WRITE = 0x0002
"""execute code only when ida is idle and it is safe to modify the database. in particular, this flag will suspend execution if there is
a modal dialog box on the screen this mode can be used to call any ida api function. MFF_WRITE implies MFF_READ"""

MFF_NOWAIT = 0x0004
"""Do not wait for the request to be executed.
he caller should ensure that the request is not
destroyed until the execution completes.
if not, the request will be ignored.
the return code of execute_sync() is meaningless
in this case.
This flag can be used to delay the code execution
until the next UI loop run even from the main thread"""

def execute_sync(callable, reqf):
    """
    Executes a function in the context of the main thread.
    If the current thread not the main thread, then the call is queued and
    executed afterwards.

    @note: The Python version of execute_sync() cannot be called from a different thread
           for the time being.
    @param callable: A python callable object
    @param reqf: one of MFF_ flags
    @return: -1 or the return value of the callable
    """
    pass
#</pydoc>
*/
//------------------------------------------------------------------------
static int py_execute_sync(PyObject *py_callable, int reqf)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  int rc = -1;
  // Callable?
  if ( PyCallable_Check(py_callable) )
  {
    struct py_exec_request_t : exec_request_t
    {
      ref_t py_callable;
      virtual int idaapi execute()
      {
        PYW_GIL_GET;
        newref_t py_result(PyObject_CallFunctionObjArgs(py_callable.o, NULL));
        int ret = py_result == NULL || !PyInt_Check(py_result.o)
                ? -1
                : PyInt_AsLong(py_result.o);
        // if the requesting thread decided not to wait for the request to
        // complete, we have to self-destroy, nobody else will do it
        if ( (code & MFF_NOWAIT) != 0 )
          delete this;
        return ret;
      }
      py_exec_request_t(PyObject *pyc)
      {
        // No need to GIL-ensure here, since this is created
        // within the py_execute_sync() scope.
        py_callable = borref_t(pyc);
      }
      virtual ~py_exec_request_t()
      {
        // Need to GIL-ensure here, since this might be called
        // from the main thread.
        PYW_GIL_GET;
        py_callable = ref_t(); // Release callable
      }
    };
    py_exec_request_t *req = new py_exec_request_t(py_callable);

    // Release GIL before executing, or if this is running in the
    // non-main thread, this will wait on the req.sem, while the main
    // thread might be waiting for the GIL to be available.
    Py_BEGIN_ALLOW_THREADS;
    rc = execute_sync(*req, reqf);
    Py_END_ALLOW_THREADS;
    // destroy the request once it is finished. exception: NOWAIT requests
    // will be handled in the future, so do not destroy them yet!
    if ( (reqf & MFF_NOWAIT) == 0 )
      delete req;
  }
  return rc;
}

//------------------------------------------------------------------------
/*
#<pydoc>

def execute_ui_requests(callable_list):
    """
    Inserts a list of callables into the UI message processing queue.
    When the UI is ready it will call one callable.
    A callable can request to be called more than once if it returns True.

    @param callable_list: A list of python callable objects.
    @note: A callable should return True if it wants to be called more than once.
    @return: Boolean. False if the list contains a non callabale item
    """
    pass
#</pydoc>
*/
static bool py_execute_ui_requests(PyObject *py_list)
{
  struct py_ui_request_t: public ui_request_t
  {
  private:
    ref_vec_t py_callables;
    size_t py_callable_idx;

    static int idaapi s_py_list_walk_cb(
            const ref_t &py_item,
            Py_ssize_t index,
            void *ud)
    {
      PYW_GIL_CHECK_LOCKED_SCOPE();
      // Not callable? Terminate iteration
      if ( !PyCallable_Check(py_item.o) )
        return CIP_FAILED;

      // Append this callable and increment its reference
      py_ui_request_t *_this = (py_ui_request_t *)ud;
      _this->py_callables.push_back(py_item);
      return CIP_OK;
    }
  public:
    py_ui_request_t(): py_callable_idx(0)
    {
    }

    virtual bool idaapi run()
    {
      PYW_GIL_GET;

      // Get callable
      ref_t py_callable = py_callables.at(py_callable_idx);
      bool reschedule;
      newref_t py_result(PyObject_CallFunctionObjArgs(py_callable.o, NULL));
      reschedule = py_result != NULL && PyObject_IsTrue(py_result.o);

      // No rescheduling? Then advance to the next callable
      if ( !reschedule )
        ++py_callable_idx;

      // Reschedule this C callback only if there are more callables
      return py_callable_idx < py_callables.size();
    }

    // Walk the list and extract all callables
    bool init(PyObject *py_list)
    {
      Py_ssize_t count = pyvar_walk_list(
        py_list,
        s_py_list_walk_cb,
        this);
      return count > 0;
    }

    virtual idaapi ~py_ui_request_t()
    {
      py_callables.clear();
    }
  };

  py_ui_request_t *req = new py_ui_request_t();
  if ( !req->init(py_list) )
  {
    delete req;
    return false;
  }
  execute_ui_requests(req, NULL);
  return true;
}

//------------------------------------------------------------------------
/*
#<pydoc>
def set_dock_pos(src, dest, orient, left = 0, top = 0, right = 0, bottom = 0):
    """
    Sets the dock orientation of a window relatively to another window.

    @param src: Source docking control
    @param dest: Destination docking control
    @param orient: One of DOR_XXXX constants
    @param left, top, right, bottom: These parameter if DOR_FLOATING is used, or if you want to specify the width of docked windows
    @return: Boolean

    Example:
        set_dock_pos('Structures', 'Enums', DOR_RIGHT) <- docks the Structures window to the right of Enums window
    """
    pass
#</pydoc>
*/

//------------------------------------------------------------------------
/*
#<pydoc>
def is_idaq():
    """
    Returns True or False depending if IDAPython is hosted by IDAQ
    """
#</pydoc>
*/

//---------------------------------------------------------------------------
// UI hooks
//---------------------------------------------------------------------------
int idaapi UI_Callback(void *ud, int notification_code, va_list va);
/*
#<pydoc>
class UI_Hooks(object):
    def hook(self):
        """
        Creates an UI hook

        @return: Boolean true on success
        """
        pass

    def unhook(self):
        """
        Removes the UI hook
        @return: Boolean true on success
        """
        pass

    def preprocess(self, name):
        """
        IDA ui is about to handle a user command

        @param name: ui command name
                     (these names can be looked up in ida[tg]ui.cfg)
        @return: 0-ok, nonzero - a plugin has handled the command
        """
        pass

    def postprocess(self):
        """
        An ida ui command has been handled

        @return: Ignored
        """
        pass

    def saving(self):
        """
        The kernel is saving the database.

        @return: Ignored
        """
        pass

    def saved(self):
        """
        The kernel has saved the database.

        @return: Ignored
        """
        pass

    def get_ea_hint(self, ea):
        """
        The UI wants to display a simple hint for an address in the navigation band

        @param ea: The address
        @return: String with the hint or None
        """
        pass

    def updating_actions(self, ctx):
        """
        The UI is about to batch-update some actions.

        @param ctx: The action_update_ctx_t instance
        @return: Ignored
        """
        pass

    def updated_actions(self):
        """
        The UI is done updating actions.

        @return: Ignored
        """
        pass

    def populating_tform_popup(self, form, popup):
        """
        The UI is populating the TForm's popup menu.
        Now is a good time to call idaapi.attach_action_to_popup()

        @param form: The form
        @param popup: The popup menu.
        @return: Ignored
        """
        pass

    def finish_populating_tform_popup(self, form, popup):
        """
        The UI is about to be done populating the TForm's popup menu.
        Now is a good time to call idaapi.attach_action_to_popup()

        @param form: The form
        @param popup: The popup menu.
        @return: Ignored
        """
        pass

    def term(self):
        """
        IDA is terminated and the database is already closed.
        The UI may close its windows in this callback.
        """
        # if the user forgot to call unhook, do it for him
        self.unhook()

    def __term__(self):
        self.term()

#</pydoc>
*/
class UI_Hooks
{
public:
  virtual ~UI_Hooks()
  {
    unhook();
  }

  bool hook()
  {
    return hook_to_notification_point(HT_UI, UI_Callback, this);
  }

  bool unhook()
  {
    return unhook_from_notification_point(HT_UI, UI_Callback, this);
  }

  virtual int preprocess(const char * /*name*/)
  {
    return 0;
  }

  virtual void postprocess()
  {
  }

  virtual void saving()
  {
  }

  virtual void saved()
  {
  }

  virtual void term()
  {
  }

  virtual PyObject *get_ea_hint(ea_t /*ea*/)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    Py_RETURN_NONE;
  };

  virtual void current_tform_changed(TForm * /*form*/, TForm * /*previous_form*/)
  {
  }

  virtual void updating_actions(action_update_ctx_t *ctx)
  {
  }

  virtual void updated_actions()
  {
  }

  virtual void populating_tform_popup(TForm * /*form*/, TPopupMenu * /*popup*/)
  {
  }

  virtual void finish_populating_tform_popup(TForm * /*form*/, TPopupMenu * /*popup*/)
  {
  }
};

//-------------------------------------------------------------------------
bool py_register_action(action_desc_t *desc)
{
  bool ok = register_action(*desc);
  if ( ok )
  {
    // Success. We are managing this handler from now on,
    // and must prevent it from being destroyed.
    py_action_handlers[desc->name] = desc->handler;
    // Let's set this to NULL, so when the wrapping Python action_desc_t
    // instance is deleted, it doesn't try to delete the handler (See
    // kernwin.i's action_desc_t::~action_desc_t()).
    desc->handler = NULL;
  }
  return ok;
}

//-------------------------------------------------------------------------
bool py_unregister_action(const char *name)
{
  bool ok = unregister_action(name);
  if ( ok )
  {
    py_action_handler_t *handler =
      (py_action_handler_t *) py_action_handlers[name];
    delete handler;
    py_action_handlers.erase(name);
  }
  return ok;
}

//-------------------------------------------------------------------------
bool py_attach_dynamic_action_to_popup(
        TForm *form,
        TPopupMenu *popup_handle,
        action_desc_t *desc,
        const char *popuppath = NULL,
        int flags = 0)
{
  bool ok = attach_dynamic_action_to_popup(
          form, popup_handle, *desc, popuppath, flags);
  if ( ok )
    // Set the handler to null, so the desc won't destroy
    // it, as it noticed ownership was taken by IDA.
    // In addition, we don't need to register into the
    // 'py_action_handlers', because IDA will destroy the
    // handler as soon as the popup menu is closed.
    desc->handler = NULL;
  return ok;
}

// This is similar to a twinline_t, with improved memory management:
// twinline_t has a dummy destructor, that performs no cleanup.
struct disasm_line_t
{
  disasm_line_t() : at(NULL) {}
  ~disasm_line_t() { qfree(at); }
  disasm_line_t(const disasm_line_t &other) { *this = other; }
  disasm_line_t &operator=(const disasm_line_t &other)
  {
    qfree(at);
    at = other.at == NULL ? NULL : other.at->clone();
    return *this;
  }
  place_t *at;
  qstring line;
  color_t prefix_color;
  bgcolor_t bg_color;
  bool is_default;
};
DECLARE_TYPE_AS_MOVABLE(disasm_line_t);
typedef qvector<disasm_line_t> disasm_text_t;

//-------------------------------------------------------------------------
void py_gen_disasm_text(ea_t ea1, ea_t ea2, disasm_text_t &text, bool truncate_lines)
{
  text_t _text;
  gen_disasm_text(ea1, ea2, _text, truncate_lines);
  for ( size_t i = 0, n = _text.size(); i < n; ++i )
  {
    const twinline_t &tl = _text[i];
    disasm_line_t &dl = text.push_back();
    dl.at = tl.at;           // Transfer ownership
    dl.line.inject(tl.line); // Transfer ownership
  }
}

//-------------------------------------------------------------------------
// Although 'TCustomControl*' and 'TForm*' instances can both be used
// for attach_action_to_popup() at a binary-level, IDAPython SWIG bindings
// require that a 'TForm *' wrapper be passed to wrap_attach_action_to_popup().
// Thus, we provide another attach_action_to_popup() version, that
// accepts a 'TCustomControl' as first argument.
//
// Since user-created GraphViewer are created like so:
// +-------- PluginForm ----------+
// |+----- TCustomControl -------+|
// ||                            ||
// ||                            ||
// ||                            ||
// ||                            ||
// ||                            ||
// |+----------------------------+|
// +------------------------------+
// The user cannot use GetTForm(), and use that to attach
// an action to, because that'll attach the action to the PluginForm
// instance.
// Instead, the user must use GetTCustomControl(), and call
// this function below with it.
bool attach_action_to_popup(
        TCustomControl *tcc,
        TPopupMenu *popup_handle,
        const char *name,
        const char *popuppath = NULL,
        int flags = 0)
{
  return attach_action_to_popup((TForm*) tcc, popup_handle, name, popuppath, flags);
}

//-------------------------------------------------------------------------
/*
#<pydoc>
def set_nav_colorizer(callback):
    """
    Set a new colorizer for the navigation band.

    The 'callback' is a function of 2 arguments:
       - ea (the EA to colorize for)
       - nbytes (the number of bytes at that EA)
    and must return a 'long' value.

    The previous colorizer is returned, allowing
    the new 'callback' to use 'call_nav_colorizer'
    with it.

    Note that the previous colorizer is returned
    only the first time set_nav_colorizer() is called:
    due to the way the colorizers API is defined in C,
    it is impossible to chain more than 2 colorizers
    in IDAPython: the original, IDA-provided colorizer,
    and a user-provided one.

    Example: colorizer inverting the color provided by the IDA colorizer:
        def my_colorizer(ea, nbytes):
            global ida_colorizer
            orig = idaapi.call_nav_colorizer(ida_colorizer, ea, nbytes)
            return long(~orig)

        ida_colorizer = idaapi.set_nav_colorizer(my_colorizer)
    """
    pass
#</pydoc>
*/
nav_colorizer_t *py_set_nav_colorizer(PyObject *new_py_colorizer)
{
  static ref_t py_colorizer;
  struct ida_local lambda_t
  {
    static uint32 idaapi call_py_colorizer(ea_t ea, asize_t nbytes)
    {
      PYW_GIL_GET;

      if ( py_colorizer == NULL ) // Shouldn't happen.
        return 0;
      newref_t pyres = PyObject_CallFunction(
              py_colorizer.o, "KK",
              (unsigned long long) ea,
              (unsigned long long) nbytes);
      PyW_ShowCbErr("nav_colorizer");
      if ( pyres.o == NULL )
        return 0;
      if ( !PyLong_Check(pyres.o) )
      {
        static bool warned = false;
        if ( !warned )
        {
          msg("WARNING: set_nav_colorizer() callback must return a 'long'.\n");
          warned = true;
        }
        return 0;
      }
      return PyLong_AsLong(pyres.o);
    }
  };

  bool need_install = py_colorizer == NULL;
  py_colorizer = borref_t(new_py_colorizer);
  return need_install
    ? set_nav_colorizer(lambda_t::call_py_colorizer)
    : NULL;
}

//-------------------------------------------------------------------------
/*
#<pydoc>
def call_nav_colorizer(colorizer, ea, nbytes):
    """
    To be used with the IDA-provided colorizer, that is
    returned as result of the first call to set_nav_colorizer().

    This is a trivial trampoline, so that SWIG can generate a
    wrapper that will do the types checking.
    """
    pass
#</pydoc>
*/
uint32 py_call_nav_colorizer(
        nav_colorizer_t *col,
        ea_t ea,
        asize_t nbytes)
{
  return col(ea, nbytes);
}



//---------------------------------------------------------------------------
uint32 idaapi choose_sizer(void *self)
{
  PYW_GIL_GET;
  newref_t pyres(PyObject_CallMethod((PyObject *)self, "sizer", ""));
  return PyInt_AsLong(pyres.o);
}

//---------------------------------------------------------------------------
char *idaapi choose_getl(void *self, uint32 n, char *buf)
{
  PYW_GIL_GET;
  newref_t pyres(
          PyObject_CallMethod(
                  (PyObject *)self,
                  "getl",
                  "l",
                  n));

  const char *res;
  if (pyres == NULL || (res = PyString_AsString(pyres.o)) == NULL )
    qstrncpy(buf, "<Empty>", MAXSTR);
  else
    qstrncpy(buf, res, MAXSTR);
  return buf;
}

//---------------------------------------------------------------------------
void idaapi choose_enter(void *self, uint32 n)
{
  PYW_GIL_GET;
  newref_t res(PyObject_CallMethod((PyObject *)self, "enter", "l", n));
}

//---------------------------------------------------------------------------
uint32 choose_choose(
    void *self,
    int flags,
    int x0,int y0,
    int x1,int y1,
    int width,
    int deflt,
    int icon)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  newref_t pytitle(PyObject_GetAttrString((PyObject *)self, "title"));
  const char *title = pytitle != NULL ? PyString_AsString(pytitle.o) : "Choose";

  int r = choose(
    flags,
    x0, y0,
    x1, y1,
    self,
    width,
    choose_sizer,
    choose_getl,
    title,
    icon,
    deflt,
    NULL, /* del */
    NULL, /* inst */
    NULL, /* update */
    NULL, /* edit */
    choose_enter,
    NULL, /* destroy */
    NULL, /* popup_names */
    NULL);/* get_icon */

  return r;
}


PyObject *choose2_find(const char *title);
int choose2_add_command(PyObject *self, const char *caption, int flags, int menu_index, int icon);
void choose2_refresh(PyObject *self);
void choose2_close(PyObject *self);
int choose2_create(PyObject *self, bool embedded);
void choose2_activate(PyObject *self);
PyObject *choose2_get_embedded(PyObject *self);
PyObject *choose2_get_embedded_selection(PyObject *self);


#define DECLARE_FORM_ACTIONS form_actions_t *fa = (form_actions_t *)p_fa;

//---------------------------------------------------------------------------
static bool textctrl_info_t_assign(PyObject *self, PyObject *other)
{
  textctrl_info_t *lhs = textctrl_info_t_get_clink(self);
  textctrl_info_t *rhs = textctrl_info_t_get_clink(other);
  if (lhs == NULL || rhs == NULL)
    return false;

  *lhs = *rhs;
  return true;
}

//-------------------------------------------------------------------------
static bool textctrl_info_t_set_text(PyObject *self, const char *s)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  if ( ti == NULL )
    return false;
  ti->text = s;
  return true;
}

//-------------------------------------------------------------------------
static const char *textctrl_info_t_get_text(PyObject *self)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  return ti == NULL ? "" : ti->text.c_str();
}

//-------------------------------------------------------------------------
static bool textctrl_info_t_set_flags(PyObject *self, unsigned int flags)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  if ( ti == NULL )
    return false;
  ti->flags = flags;
  return true;
}

//-------------------------------------------------------------------------
static unsigned int textctrl_info_t_get_flags(
    PyObject *self,
    unsigned int flags)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  return ti == NULL ? 0 : ti->flags;
}

//-------------------------------------------------------------------------
static bool textctrl_info_t_set_tabsize(
    PyObject *self,
    unsigned int tabsize)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  if ( ti == NULL )
    return false;
  ti->tabsize = tabsize;
  return true;
}

//-------------------------------------------------------------------------
static unsigned int textctrl_info_t_get_tabsize(
  PyObject *self,
  unsigned int tabsize)
{
  textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(self);
  return ti == NULL ? 0 : ti->tabsize;
}

//---------------------------------------------------------------------------
static bool formchgcbfa_enable_field(size_t p_fa, int fid, bool enable)
{
  DECLARE_FORM_ACTIONS;
  return fa->enable_field(fid, enable);
}

//---------------------------------------------------------------------------
static bool formchgcbfa_show_field(size_t p_fa, int fid, bool show)
{
  DECLARE_FORM_ACTIONS;
  return fa->show_field(fid, show);
}

//---------------------------------------------------------------------------
static bool formchgcbfa_move_field(
    size_t p_fa,
    int fid,
    int x,
    int y,
    int w,
    int h)
{
  DECLARE_FORM_ACTIONS;
  return fa->move_field(fid, x, y, w, h);
}

//---------------------------------------------------------------------------
static int formchgcbfa_get_focused_field(size_t p_fa)
{
  DECLARE_FORM_ACTIONS;
  return fa->get_focused_field();
}

//---------------------------------------------------------------------------
static bool formchgcbfa_set_focused_field(size_t p_fa, int fid)
{
  DECLARE_FORM_ACTIONS;
  return fa->set_focused_field(fid);
}

//---------------------------------------------------------------------------
static void formchgcbfa_refresh_field(size_t p_fa, int fid)
{
  DECLARE_FORM_ACTIONS;
  return fa->refresh_field(fid);
}

//---------------------------------------------------------------------------
static void formchgcbfa_close(size_t p_fa, int close_normally)
{
  DECLARE_FORM_ACTIONS;
  fa->close(close_normally);
}

//---------------------------------------------------------------------------
static PyObject *formchgcbfa_get_field_value(
    size_t p_fa,
    int fid,
    int ft,
    size_t sz)
{
  DECLARE_FORM_ACTIONS;
  PYW_GIL_CHECK_LOCKED_SCOPE();
  switch ( ft )
  {
    // dropdown list
    case 8:
    {
      // Readonly? Then return the selected index
      if ( sz == 1 )
      {
        int sel_idx;
        if ( fa->get_combobox_value(fid, &sel_idx) )
          return PyLong_FromLong(sel_idx);
      }
      // Not readonly? Then return the qstring
      else
      {
        qstring val;
        if ( fa->get_combobox_value(fid, &val) )
          return PyString_FromString(val.c_str());
      }
      break;
    }
    // multilinetext - tuple representing textctrl_info_t
    case 7:
    {
      textctrl_info_t ti;
      if ( fa->get_text_value(fid, &ti) )
        return Py_BuildValue("(sII)", ti.text.c_str(), ti.flags, ti.tabsize);
      break;
    }
    // button - uint32
    case 4:
    {
      uval_t val;
      if ( fa->get_unsigned_value(fid, &val) )
        return PyLong_FromUnsignedLong(val);
      break;
    }
    // ushort
    case 2:
    {
      ushort val;
      if ( fa->_get_field_value(fid, &val) )
        return PyLong_FromUnsignedLong(val);
      break;
    }
    // string label
    case 1:
    {
      char val[MAXSTR];
      if ( fa->get_ascii_value(fid, val, sizeof(val)) )
        return PyString_FromString(val);
      break;
    }
    // string input
    case 3:
    {
      qstring val;
      val.resize(sz + 1);
      if ( fa->get_ascii_value(fid, val.begin(), val.size()) )
        return PyString_FromString(val.begin());
      break;
    }
    case 5:
    {
      intvec_t intvec;
      // Returned as 1-base
      if (fa->get_chooser_value(fid, &intvec))
      {
        // Make 0-based
        for ( intvec_t::iterator it=intvec.begin(); it != intvec.end(); ++it)
          (*it)--;
        ref_t l(PyW_IntVecToPyList(intvec));
        l.incref();
        return l.o;
      }
      break;
    }
    // Numeric control
    case 6:
    {
      union
      {
        sel_t sel;
        sval_t sval;
        uval_t uval;
        ulonglong ull;
      } u;
      switch ( sz )
      {
        case 'S': // sel_t
        {
          if ( fa->get_segment_value(fid, &u.sel) )
            return Py_BuildValue(PY_FMT64, u.sel);
          break;
        }
        // sval_t
        case 'n':
        case 'D':
        case 'O':
        case 'Y':
        case 'H':
        {
          if ( fa->get_signed_value(fid, &u.sval) )
            return Py_BuildValue(PY_SFMT64, u.sval);
          break;
        }
        case 'L': // uint64
        case 'l': // int64
        {
          if ( fa->_get_field_value(fid, &u.ull) )
            return Py_BuildValue("K", u.ull);
          break;
        }
        case 'N':
        case 'M': // uval_t
        {
          if ( fa->get_unsigned_value(fid, &u.uval) )
            return Py_BuildValue(PY_FMT64, u.uval);
          break;
        }
        case '$': // ea_t
        {
          if ( fa->get_ea_value(fid, &u.uval) )
            return Py_BuildValue(PY_FMT64, u.uval);
          break;
        }
      }
      break;
    }
  }
  Py_RETURN_NONE;
}

//---------------------------------------------------------------------------
static bool formchgcbfa_set_field_value(
  size_t p_fa,
  int fid,
  int ft,
  PyObject *py_val)
{
  DECLARE_FORM_ACTIONS;
  PYW_GIL_CHECK_LOCKED_SCOPE();

  switch ( ft )
  {
    // dropdown list
    case 8:
    {
      // Editable dropdown list
      if ( PyString_Check(py_val) )
      {
        qstring val(PyString_AsString(py_val));
        return fa->set_combobox_value(fid, &val);
      }
      // Readonly dropdown list
      else
      {
        int sel_idx = PyLong_AsLong(py_val);
        return fa->set_combobox_value(fid, &sel_idx);
      }
      break;
    }
    // multilinetext - textctrl_info_t
    case 7:
    {
      textctrl_info_t *ti = (textctrl_info_t *)pyobj_get_clink(py_val);
      return ti == NULL ? false : fa->set_text_value(fid, ti);
    }
    // button - uint32
    case 4:
    {
      uval_t val = PyLong_AsUnsignedLong(py_val);
      return fa->set_unsigned_value(fid, &val);
    }
    // ushort
    case 2:
    {
      ushort val = PyLong_AsUnsignedLong(py_val) & 0xffff;
      return fa->_set_field_value(fid, &val);
    }
    // strings
    case 3:
    case 1:
      return fa->set_ascii_value(fid, PyString_AsString(py_val));
    // intvec_t
    case 5:
    {
      intvec_t intvec;
      // Passed as 0-based
      if ( !PyW_PyListToIntVec(py_val, intvec) )
        break;

      // Make 1-based
      for ( intvec_t::iterator it=intvec.begin(); it != intvec.end(); ++it)
        (*it)++;

      return fa->set_chooser_value(fid, &intvec);
    }
    // Numeric
    case 6:
    {
      uint64 num;
      if ( PyW_GetNumber(py_val, &num) )
        return fa->_set_field_value(fid, &num);
    }
  }
  return false;
}

#undef DECLARE_FORM_ACTIONS

static size_t py_get_AskUsingForm()
{
  // Return a pointer to the function. Note that, although
  // the C implementation of AskUsingForm_cv will do some
  // Qt/txt widgets generation, the Python's ctypes
  // implementation through which the call well go will first
  // unblock other threads. No need to do it ourselves.
  return (size_t)AskUsingForm_c;
}

static size_t py_get_OpenForm()
{
  // See comments above.
  return (size_t)OpenForm_c;
}

static qvector<ref_t> py_compiled_form_vec;
static void py_register_compiled_form(PyObject *py_form)
{
  ref_t ref = borref_t(py_form);
  if ( !py_compiled_form_vec.has(ref) )
    py_compiled_form_vec.push_back(ref);
}

static void py_unregister_compiled_form(PyObject *py_form)
{
  ref_t ref = borref_t(py_form);
  if ( py_compiled_form_vec.has(ref) )
    py_compiled_form_vec.del(ref);
}

//</inline(py_kernwin)>
%}

%{
//<code(py_kernwin)>
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
int idaapi UI_Callback(void *ud, int notification_code, va_list va)
{
  // This hook gets called from the kernel. Ensure we hold the GIL.
  PYW_GIL_GET;
  UI_Hooks *proxy = (UI_Hooks *)ud;
  int ret = 0;
  try
  {
    switch (notification_code)
    {
      case ui_preprocess:
      {
        const char *name = va_arg(va, const char *);
        return proxy->preprocess(name);
      }

      case ui_postprocess:
        proxy->postprocess();
        break;

      case ui_saving:
        proxy->saving();
        break;

      case ui_saved:
        proxy->saved();
        break;

      case ui_term:
        proxy->term();
        break;

      case ui_get_ea_hint:
      {
        ea_t ea = va_arg(va, ea_t);
        char *buf = va_arg(va, char *);
        size_t sz = va_arg(va, size_t);
        char *_buf;
        Py_ssize_t _len;

        PYW_GIL_CHECK_LOCKED_SCOPE();
        PyObject *py_str = proxy->get_ea_hint(ea);
        if ( py_str != NULL
          && PyString_Check(py_str)
          && PyString_AsStringAndSize(py_str, &_buf, &_len) != - 1 )
        {
          qstrncpy(buf, _buf, qmin(_len, sz));
          ret = 1;
        }
        break;
      }

      case ui_current_tform_changed:
        {
          TForm *form = va_arg(va, TForm *);
          TForm *prev_form = va_arg(va, TForm *);
          proxy->current_tform_changed(form, prev_form);
        }
        break;

      case ui_updating_actions:
        {
          action_update_ctx_t *ctx = va_arg(va, action_update_ctx_t *);
          proxy->updating_actions(ctx);
        }
        break;


      case ui_updated_actions:
        {
          proxy->updated_actions();
        }
        break;

      case ui_populating_tform_popup:
        {
          TForm *form = va_arg(va, TForm *);
          TPopupMenu *popup = va_arg(va, TPopupMenu *);
          proxy->populating_tform_popup(form, popup);
        }
        break;

      case ui_finish_populating_tform_popup:
        {
          TForm *form = va_arg(va, TForm *);
          TPopupMenu *popup = va_arg(va, TPopupMenu *);
          proxy->finish_populating_tform_popup(form, popup);
        }
        break;
    }
  }
  catch (Swig::DirectorException &e)
  {
    msg("Exception in UI Hook function: %s\n", e.getMessage());
    PYW_GIL_CHECK_LOCKED_SCOPE();
    if ( PyErr_Occurred() )
      PyErr_Print();
  }
  return ret;
}

//------------------------------------------------------------------------
bool idaapi py_menu_item_callback(void *userdata)
{
  PYW_GIL_GET;

  // userdata is a tuple of ( func, args )
  // func and args are borrowed references from userdata
  PyObject *func = PyTuple_GET_ITEM(userdata, 0);
  PyObject *args = PyTuple_GET_ITEM(userdata, 1);

  // Call the python function
  newref_t result(PyEval_CallObject(func, args));

  // We cannot raise an exception in the callback, just print it.
  if ( result == NULL )
  {
    PyErr_Print();
    return false;
  }

  return PyObject_IsTrue(result.o) != 0;
}



//------------------------------------------------------------------------
// Some defines
#define POPUP_NAMES_COUNT 4
#define MAX_CHOOSER_MENU_COMMANDS 20
#define thisobj ((py_choose2_t *) obj)
#define thisdecl py_choose2_t *_this = thisobj
#define MENU_COMMAND_CB(id) \
  static uint32 idaapi s_menu_command_##id(void *obj, uint32 n) \
  {                                                             \
    return thisobj->on_command(id, int(n));                     \
  }

//------------------------------------------------------------------------
// Helper functions
class py_choose2_t;
typedef std::map<PyObject *, py_choose2_t *> pychoose2_to_choose2_map_t;
static pychoose2_to_choose2_map_t choosers;

py_choose2_t *choose2_find_instance(PyObject *self)
{
  pychoose2_to_choose2_map_t::iterator it = choosers.find(self);
  return it == choosers.end() ? NULL : it->second;
}

void choose2_add_instance(PyObject *self, py_choose2_t *c2)
{
  choosers[self] = c2;
}

void choose2_del_instance(PyObject *self)
{
  pychoose2_to_choose2_map_t::iterator it = choosers.find(self);
  if ( it != choosers.end() )
    choosers.erase(it);
}

//------------------------------------------------------------------------
class py_choose2_t
{
private:
  enum
  {
    CHOOSE2_HAVE_DEL       = 0x0001,
    CHOOSE2_HAVE_INS       = 0x0002,
    CHOOSE2_HAVE_UPDATE    = 0x0004,
    CHOOSE2_HAVE_EDIT      = 0x0008,
    CHOOSE2_HAVE_ENTER     = 0x0010,
    CHOOSE2_HAVE_GETICON   = 0x0020,
    CHOOSE2_HAVE_GETATTR   = 0x0040,
    CHOOSE2_HAVE_COMMAND   = 0x0080,
    CHOOSE2_HAVE_ONCLOSE   = 0x0100,
    CHOOSE2_HAVE_SELECT    = 0x0200,
    CHOOSE2_HAVE_REFRESHED = 0x0400,
  };
  // Chooser flags
  int flags;

  // Callback flags (to tell which callback exists and which not)
  // One of CHOOSE2_HAVE_xxxx
  unsigned int cb_flags;
  chooser_info_t *embedded;
  intvec_t embedded_sel;

  // Menu callback index (in the menu_cbs array)
  int menu_cb_idx;

  // Chooser title
  qstring title;

  // Column widths
  intvec_t widths;

  // Python object link
  PyObject *self;
  // Chooser columns
  qstrvec_t cols;
  const char **popup_names;
  bool ui_cb_hooked;

  // The number of declarations should follow the MAX_CHOOSER_MENU_COMMANDS value
  MENU_COMMAND_CB(0)   MENU_COMMAND_CB(1)
  MENU_COMMAND_CB(2)   MENU_COMMAND_CB(3)
  MENU_COMMAND_CB(4)   MENU_COMMAND_CB(5)
  MENU_COMMAND_CB(6)   MENU_COMMAND_CB(7)
  MENU_COMMAND_CB(8)   MENU_COMMAND_CB(9)
  MENU_COMMAND_CB(10)  MENU_COMMAND_CB(11)
  MENU_COMMAND_CB(12)  MENU_COMMAND_CB(13)
  MENU_COMMAND_CB(14)  MENU_COMMAND_CB(15)
  MENU_COMMAND_CB(16)  MENU_COMMAND_CB(17)
  MENU_COMMAND_CB(18)  MENU_COMMAND_CB(19)
  static chooser_cb_t *menu_cbs[MAX_CHOOSER_MENU_COMMANDS];

  //------------------------------------------------------------------------
  // Static methods to dispatch to member functions
  //------------------------------------------------------------------------
  static int idaapi ui_cb(void *obj, int notification_code, va_list va)
  {
    // This hook gets called from the kernel. Ensure we hold the GIL.
    PYW_GIL_GET;

    // UI callback to handle chooser items with attributes
    if ( notification_code != ui_get_chooser_item_attrs )
      return 0;

    // Pass events that belong to our chooser only
    void *chooser_obj = va_arg(va, void *);
    if ( obj != chooser_obj )
      return 0;

    int n = int(va_arg(va, uint32));
    chooser_item_attrs_t *attr = va_arg(va, chooser_item_attrs_t *);
    thisobj->on_get_line_attr(n, attr);
    return 1;
  }

  static void idaapi s_select(void *obj, const intvec_t &sel)
  {
    thisobj->on_select(sel);
  }

  static void idaapi s_refreshed(void *obj)
  {
    thisobj->on_refreshed();
  }

  static uint32 idaapi s_sizer(void *obj)
  {
    return (uint32)thisobj->on_get_size();
  }

  static void idaapi s_getl(void *obj, uint32 n, char * const *arrptr)
  {
    thisobj->on_get_line(int(n), arrptr);
  }

  static uint32 idaapi s_del(void *obj, uint32 n)
  {
    return uint32(thisobj->on_delete_line(int(n)));
  }

  static void idaapi s_ins(void *obj)
  {
    thisobj->on_insert_line();
  }

  static uint32 idaapi s_update(void *obj, uint32 n)
  {
    return uint32(thisobj->on_refresh(int(n)));
  }

  static void idaapi s_edit(void *obj, uint32 n)
  {
    thisobj->on_edit_line(int(n));
  }

  static void idaapi s_enter(void * obj, uint32 n)
  {
    thisobj->on_enter(int(n));
  }

  static int idaapi s_get_icon(void *obj, uint32 n)
  {
    return thisobj->on_get_icon(int(n));
  }

  static void idaapi s_destroy(void *obj)
  {
    thisobj->on_close();
  }

  //------------------------------------------------------------------------
  // Member functions corresponding to each chooser2() callback
  //------------------------------------------------------------------------
  void clear_popup_names()
  {
    if ( popup_names == NULL )
      return;

    for ( int i=0; i<POPUP_NAMES_COUNT; i++ )
      qfree((void *)popup_names[i]);

    delete [] popup_names;
    popup_names = NULL;
  }

  void install_hooks(bool install)
  {
    if ( install )
    {
      if ( (flags & CH_ATTRS) != 0 )
      {
        if ( !hook_to_notification_point(HT_UI, ui_cb, this) )
          flags &= ~CH_ATTRS;
        else
          ui_cb_hooked = true;
      }
    }
    else
    {
      if ( (flags & CH_ATTRS) != 0 )
      {
        unhook_from_notification_point(HT_UI, ui_cb, this);
        ui_cb_hooked = false;
      }
    }
  }

  void on_get_line(int lineno, char * const *line_arr)
  {
    // Called from s_getl, which itself can be called from the kernel. Ensure GIL
    PYW_GIL_GET;

    // Get headers?
    if ( lineno == 0 )
    {
      // Copy the pre-parsed columns
      for ( size_t i=0; i < cols.size(); i++ )
        qstrncpy(line_arr[i], cols[i].c_str(), MAXSTR);
      return;
    }

    // Clear buffer
    int ncols = int(cols.size());
    for ( int i=ncols-1; i>=0; i-- )
      line_arr[i][0] = '\0';

    // Call Python
    PYW_GIL_CHECK_LOCKED_SCOPE();
    pycall_res_t list(PyObject_CallMethod(self, (char *)S_ON_GET_LINE, "i", lineno - 1));
    if ( list.result == NULL )
      return;

    // Go over the List returned by Python and convert to C strings
    for ( int i=ncols-1; i>=0; i-- )
    {
      borref_t item(PyList_GetItem(list.result.o, Py_ssize_t(i)));
      if ( item == NULL )
        continue;

      const char *str = PyString_AsString(item.o);
      if ( str != NULL )
        qstrncpy(line_arr[i], str, MAXSTR);
    }
  }

  size_t on_get_size()
  {
    PYW_GIL_GET;
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_GET_SIZE, NULL));
    if ( pyres.result == NULL )
      return 0;

    return PyInt_AsLong(pyres.result.o);
  }

  void on_refreshed()
  {
    PYW_GIL_GET;
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_REFRESHED, NULL));
  }

  void on_select(const intvec_t &intvec)
  {
    PYW_GIL_GET;
    ref_t py_list(PyW_IntVecToPyList(intvec));
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_SELECTION_CHANGE, "O", py_list.o));
  }

  void on_close()
  {
    PYW_GIL_GET;
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_CLOSE, NULL));

    // Delete this instance if none modal and not embedded
    if ( !is_modal() && get_embedded() == NULL )
      delete this;
  }

  int on_delete_line(int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_DELETE_LINE,
                    "i",
                    IS_CHOOSER_EVENT(lineno) ? lineno : lineno-1));
    return pyres.result == NULL ? 1 : PyInt_AsLong(pyres.result.o);
  }

  int on_refresh(int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_REFRESH,
                    "i",
                    lineno - 1));
    return pyres.result == NULL ? lineno : PyInt_AsLong(pyres.result.o) + 1;
  }

  void on_insert_line()
  {
    PYW_GIL_GET;
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_INSERT_LINE, NULL));
  }

  void on_enter(int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_SELECT_LINE,
                    "i",
                    lineno - 1));
  }

  void on_edit_line(int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_EDIT_LINE,
                    "i",
                    lineno - 1));
  }

  int on_command(int cmd_id, int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_COMMAND,
                    "ii",
                    lineno - 1,
                    cmd_id));
    return pyres.result == NULL ? lineno : PyInt_AsLong(pyres.result.o);
  }

  int on_get_icon(int lineno)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_GET_ICON,
                    "i",
                    lineno - 1));
    return PyInt_AsLong(pyres.result.o);
  }

  void on_get_line_attr(int lineno, chooser_item_attrs_t *attr)
  {
    PYW_GIL_GET;
    pycall_res_t pyres(PyObject_CallMethod(self, (char *)S_ON_GET_LINE_ATTR, "i", lineno - 1));
    if ( pyres.result != NULL )
    {
      if ( PyList_Check(pyres.result.o) )
      {
        PyObject *item;
        if ( (item = PyList_GetItem(pyres.result.o, 0)) != NULL )
          attr->color = PyInt_AsLong(item);
        if ( (item = PyList_GetItem(pyres.result.o, 1)) != NULL )
          attr->flags = PyInt_AsLong(item);
      }
    }
  }

  bool split_chooser_caption(qstring *out_title, qstring *out_caption, const char *caption) const
  {
    if ( get_embedded() != NULL )
    {
      // For embedded chooser, the "caption" will be overloaded to encode
      // the AskUsingForm's title, caption and embedded chooser id
      // Title:EmbeddedChooserID:Caption

      char title_buf[MAXSTR];
      const char *ptitle;

      static const char delimiter[] = ":";
      char temp[MAXSTR];
      qstrncpy(temp, caption, sizeof(temp));

      char *ctx;
      char *p = qstrtok(temp, delimiter, &ctx);
      if ( p == NULL )
        return false;

      // Copy the title
      char title_str[MAXSTR];
      qstrncpy(title_str, p, sizeof(title_str));

      // Copy the echooser ID
      p = qstrtok(NULL, delimiter, &ctx);
      if ( p == NULL )
        return false;

      char id_str[10];
      qstrncpy(id_str, p, sizeof(id_str));

      // Form the new title of the form: "AskUsingFormTitle:EchooserId"
      qsnprintf(title_buf, sizeof(title_buf), "%s:%s", title_str, id_str);

      // Adjust the title
      *out_title = title_buf;

      // Adjust the caption
      p = qstrtok(NULL, delimiter, &ctx);
      *out_caption = caption + (p - temp);
    }
    else
    {
      *out_title = title;
      *out_caption = caption;
    }
    return true;
  }

  // This must be called at the end of create(), when many dependencies
  // have been computed (title, widths, popup_names, [cb_]flags, ...)
  void fill_chooser_info(
          chooser_info_t *out,
          int deflt,
          int desired_width,
          int desired_height,
          int icon)
  {
    memset(out, 0, sizeof(*out));
    out->obj         = this;
    out->cb          = sizeof(*out);
    out->title       = title.c_str();
    out->columns     = widths.size();
    out->deflt       = deflt;
    out->flags       = flags;
    out->width       = desired_width;
    out->height      = desired_height;
    out->icon        = icon;
    out->popup_names = popup_names;
    out->widths      = widths.begin();
    out->destroyer   = s_destroy;
    out->getl        = s_getl;
    out->sizer       = s_sizer;
    out->del         = (cb_flags & CHOOSE2_HAVE_DEL) != 0     ? s_del      : NULL;
    out->edit        = (cb_flags & CHOOSE2_HAVE_EDIT) != 0    ? s_edit     : NULL;
    out->enter       = (cb_flags & CHOOSE2_HAVE_ENTER) != 0   ? s_enter    : NULL;
    out->get_icon    = (cb_flags & CHOOSE2_HAVE_GETICON) != 0 ? s_get_icon : NULL;
    out->ins         = (cb_flags & CHOOSE2_HAVE_INS) != 0     ? s_ins      : NULL;
    out->update      = (cb_flags & CHOOSE2_HAVE_UPDATE) != 0  ? s_update   : NULL;
    out->get_attrs   = NULL;
    out->initializer = NULL;
    // Fill callbacks that are only present in idaq
    if ( is_idaq() )
    {
      out->select = (cb_flags & CHOOSE2_HAVE_SELECT)   != 0 ? s_select    : NULL;
      out->refresh = (cb_flags & CHOOSE2_HAVE_REFRESHED)!= 0 ? s_refreshed : NULL;
    }
    else
    {
      out->select = NULL;
      out->refresh = NULL;
    }
  }

public:
  //------------------------------------------------------------------------
  // Public methods
  //------------------------------------------------------------------------
  py_choose2_t(): flags(0), cb_flags(0),
                  embedded(NULL), menu_cb_idx(0),
                  self(NULL), popup_names(NULL), ui_cb_hooked(false)
  {
  }

  ~py_choose2_t()
  {
    // Remove from list
    choose2_del_instance(self);

    // Uninstall hooks
    install_hooks(false);

    delete embedded;
    Py_XDECREF(self);
    clear_popup_names();
  }

  static py_choose2_t *find_chooser(const char *title)
  {
    return (py_choose2_t *) get_chooser_obj(title);
  }

  void close()
  {
    // Will trigger on_close()
    close_chooser(title.c_str());
  }

  bool activate()
  {
    TForm *frm = find_tform(title.c_str());
    if ( frm == NULL )
      return false;

    switchto_tform(frm, true);
    return true;
  }

  int add_command(
          const char *_caption,
          int flags=0,
          int menu_index=-1,
          int icon=-1)
  {
    if ( menu_cb_idx >= MAX_CHOOSER_MENU_COMMANDS )
      return -1;

    qstring title, caption;
    if ( !split_chooser_caption(&title, &caption, _caption)
      || !add_chooser_command(
              title.c_str(),
              caption.c_str(),
              menu_cbs[menu_cb_idx],
              menu_index,
              icon,
              flags) )
      return -1;

    return menu_cb_idx++;
  }

  // Create a chooser.
  // If it detects the "embedded" attribute, then it will create a chooser_info_t structure
  // Otherwise the chooser window is created and displayed
  int create(PyObject *self)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();

    // Get flags
    ref_t flags_attr(PyW_TryGetAttrString(self, S_FLAGS));
    if ( flags_attr == NULL )
      return -1;
    flags = PyInt_Check(flags_attr.o) != 0 ? PyInt_AsLong(flags_attr.o) : 0;

    // Get the title
    if ( !PyW_GetStringAttr(self, S_TITLE, &title) )
      return -1;

    // Get columns
    ref_t cols_attr(PyW_TryGetAttrString(self, "cols"));
    if ( cols_attr == NULL )
      return -1;

    // Get col count
    int ncols = int(PyList_Size(cols_attr.o));

    // Get cols caption and widthes
    cols.qclear();
    for ( int i=0; i<ncols; i++ )
    {
      // get list item: [name, width]
      borref_t list(PyList_GetItem(cols_attr.o, i));
      borref_t v(PyList_GetItem(list.o, 0));

      // Extract string
      const char *str = v == NULL ? "" : PyString_AsString(v.o);
      cols.push_back(str);

      // Extract width
      int width;
      borref_t v2(PyList_GetItem(list.o, 1));
      // No width? Guess width from column title
      if ( v2 == NULL )
        width = strlen(str);
      else
        width = PyInt_AsLong(v2.o);
      widths.push_back(width);
    }

    // Get *deflt
    int deflt = -1;
    ref_t deflt_attr(PyW_TryGetAttrString(self, "deflt"));
    if ( deflt_attr != NULL )
      deflt = PyInt_AsLong(deflt_attr.o);

    // Get *icon
    int icon = -1;
    ref_t icon_attr(PyW_TryGetAttrString(self, "icon"));
    if ( icon_attr != NULL )
      icon = PyInt_AsLong(icon_attr.o);

    // Get *x1,y1,x2,y2
    int pts[4];
    static const char *pt_attrs[qnumber(pts)] = {"x1", "y1", "x2", "y2"};
    for ( size_t i=0; i < qnumber(pts); i++ )
    {
      ref_t pt_attr(PyW_TryGetAttrString(self, pt_attrs[i]));
      if ( pt_attr == NULL )
        pts[i] = -1;
      else
        pts[i] = PyInt_AsLong(pt_attr.o);
    }

    // Check what callbacks we have
    static const struct
    {
      const char *name;
      unsigned int have; // 0 = mandatory callback
    } callbacks[] =
    {
      {S_ON_GET_SIZE,      0},
      {S_ON_GET_LINE,      0},
      {S_ON_CLOSE,         0},
      {S_ON_EDIT_LINE,        CHOOSE2_HAVE_EDIT},
      {S_ON_INSERT_LINE,      CHOOSE2_HAVE_INS},
      {S_ON_DELETE_LINE,      CHOOSE2_HAVE_DEL},
      {S_ON_REFRESH,          CHOOSE2_HAVE_UPDATE}, // update()
      {S_ON_SELECT_LINE,      CHOOSE2_HAVE_ENTER}, // enter()
      {S_ON_COMMAND,          CHOOSE2_HAVE_COMMAND},
      {S_ON_GET_LINE_ATTR,    CHOOSE2_HAVE_GETATTR},
      {S_ON_GET_ICON,         CHOOSE2_HAVE_GETICON},
      {S_ON_SELECTION_CHANGE, CHOOSE2_HAVE_SELECT},
      {S_ON_REFRESHED,        CHOOSE2_HAVE_REFRESHED},
    };
    cb_flags = 0;
    for ( int i=0; i<qnumber(callbacks); i++ )
    {
      ref_t cb_attr(PyW_TryGetAttrString(self, callbacks[i].name));
      bool have_cb = cb_attr != NULL && PyCallable_Check(cb_attr.o) != 0;
      if ( have_cb )
      {
        cb_flags |= callbacks[i].have;
      }
      else
      {
        // Mandatory field?
        if ( callbacks[i].have == 0 )
          return -1;
      }
    }

    // Get *popup names
    // An array of 4 strings: ("Insert", "Delete", "Edit", "Refresh"
    ref_t pn_attr(PyW_TryGetAttrString(self, S_POPUP_NAMES));
    if ( (pn_attr != NULL)
      && PyList_Check(pn_attr.o)
      && PyList_Size(pn_attr.o) == POPUP_NAMES_COUNT )
    {
      popup_names = new const char *[POPUP_NAMES_COUNT];
      for ( int i=0; i<POPUP_NAMES_COUNT; i++ )
      {
        const char *str = PyString_AsString(PyList_GetItem(pn_attr.o, i));
        popup_names[i] = qstrdup(str);
      }
    }

    // Adjust flags (if needed)
    if ( (cb_flags & CHOOSE2_HAVE_GETATTR) != 0 )
      flags |= CH_ATTRS;

    // Increase object reference
    Py_INCREF(self);
    this->self = self;

    // Hook to notification point (to handle chooser item attributes)
    install_hooks(true);

    // Check if *embedded
    ref_t emb_attr(PyW_TryGetAttrString(self, S_EMBEDDED));
    int rc;
    if ( emb_attr != NULL && PyObject_IsTrue(emb_attr.o) == 1 )
    {
      // Create an embedded chooser structure
      embedded = new chooser_info_t();
      fill_chooser_info(embedded, deflt, pts[0], pts[1], icon);
      rc = 1; // success
    }
    else
    {
      chooser_info_t ci;
      fill_chooser_info(&ci, deflt, -1, -1, icon);
      rc = choose3(&ci);
      clear_popup_names();
      if ( is_modal() )
        --rc; // modal chooser return the index of the selected item
    }
    return rc;
  }

  inline PyObject *get_self()
  {
    return self;
  }

  void refresh()
  {
    refresh_chooser(title.c_str());
  }

  bool is_modal()
  {
    return (flags & CH_MODAL) != 0;
  }

  intvec_t *get_sel_vec()
  {
    return &embedded_sel;
  }

  chooser_info_t *get_embedded() const
  {
    return embedded;
  }
};

//------------------------------------------------------------------------
// Initialize the callback pointers
#define DECL_MENU_COMMAND_CB(id) s_menu_command_##id
chooser_cb_t *py_choose2_t::menu_cbs[MAX_CHOOSER_MENU_COMMANDS] =
{
  DECL_MENU_COMMAND_CB(0),  DECL_MENU_COMMAND_CB(1),
  DECL_MENU_COMMAND_CB(2),  DECL_MENU_COMMAND_CB(3),
  DECL_MENU_COMMAND_CB(4),  DECL_MENU_COMMAND_CB(5),
  DECL_MENU_COMMAND_CB(6),  DECL_MENU_COMMAND_CB(7),
  DECL_MENU_COMMAND_CB(8),  DECL_MENU_COMMAND_CB(9),
  DECL_MENU_COMMAND_CB(10), DECL_MENU_COMMAND_CB(11),
  DECL_MENU_COMMAND_CB(12), DECL_MENU_COMMAND_CB(13),
  DECL_MENU_COMMAND_CB(14), DECL_MENU_COMMAND_CB(15),
  DECL_MENU_COMMAND_CB(16), DECL_MENU_COMMAND_CB(17),
  DECL_MENU_COMMAND_CB(18), DECL_MENU_COMMAND_CB(19)
};
#undef DECL_MENU_COMMAND_CB

#undef POPUP_NAMES_COUNT
#undef MAX_CHOOSER_MENU_COMMANDS
#undef thisobj
#undef thisdecl
#undef MENU_COMMAND_CB

//------------------------------------------------------------------------
int choose2_create(PyObject *self, bool embedded)
{
  py_choose2_t *c2;

  c2 = choose2_find_instance(self);
  if ( c2 != NULL )
  {
    if ( !embedded )
      c2->activate();
    return 1;
  }

  c2 = new py_choose2_t();

  choose2_add_instance(self, c2);

  int r = c2->create(self);
  // Non embedded chooser? Return immediately
  if ( !embedded )
    return r;

  // Embedded chooser was not created?
  if ( c2->get_embedded() == NULL || r != 1 )
  {
    delete c2;
    r = 0;
  }
  return r;
}

//------------------------------------------------------------------------
void choose2_close(PyObject *self)
{
  py_choose2_t *c2 = choose2_find_instance(self);
  if ( c2 == NULL )
    return;

  // Modal or embedded chooser?
  if ( c2->get_embedded() != NULL || c2->is_modal() )
  {
    // Then simply delete the instance
    delete c2;
  }
  else
  {
    // Close the chooser.
    // In turn this will lead to the deletion of the object
    c2->close();
  }
}

//------------------------------------------------------------------------
void choose2_refresh(PyObject *self)
{
  py_choose2_t *c2 = choose2_find_instance(self);
  if ( c2 != NULL )
    c2->refresh();
}

//------------------------------------------------------------------------
void choose2_activate(PyObject *self)
{
  py_choose2_t *c2 = choose2_find_instance(self);
  if ( c2 != NULL )
    c2->activate();
}

//------------------------------------------------------------------------
PyObject *choose2_get_embedded_selection(PyObject *self)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();

  py_choose2_t *c2 = choose2_find_instance(self);
  chooser_info_t *embedded;

  if ( c2 == NULL || (embedded = c2->get_embedded()) == NULL )
    Py_RETURN_NONE;

  // Returned as 1-based
  intvec_t &intvec = *c2->get_sel_vec();

  // Make 0-based
  for ( intvec_t::iterator it=intvec.begin(); it != intvec.end(); ++it)
    (*it)--;

  ref_t ret(PyW_IntVecToPyList(intvec));
  ret.incref();
  return ret.o;
}

//------------------------------------------------------------------------
// Return the C instances as 64bit numbers
PyObject *choose2_get_embedded(PyObject *self)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();

  py_choose2_t *c2 = choose2_find_instance(self);
  chooser_info_t *embedded;

  if ( c2 == NULL || (embedded = c2->get_embedded()) == NULL )
    Py_RETURN_NONE;
  else
    return Py_BuildValue("(KK)",
                         PY_ULONG_LONG(embedded),
                         PY_ULONG_LONG(c2->get_sel_vec()));
}

//------------------------------------------------------------------------
int choose2_add_command(
        PyObject *self,
        const char *caption,
        int flags=0,
        int menu_index=-1,
        int icon=-1)
{
  py_choose2_t *c2 = choose2_find_instance(self);
  return c2 == NULL ? -2 : c2->add_command(caption, flags, menu_index, icon);
}

//------------------------------------------------------------------------
PyObject *choose2_find(const char *title)
{
  py_choose2_t *c2 = py_choose2_t::find_chooser(title);
  return c2 == NULL ? NULL : c2->get_self();
}


void free_compiled_form_instances(void)
{
  while ( !py_compiled_form_vec.empty() )
  {
    const ref_t &ref = py_compiled_form_vec[0];
    qstring title;
    if ( !PyW_GetStringAttr(ref.o, "title", &title) )
      title = "<unknown title>";
    msg("WARNING: Form \"%s\" was not Free()d. Force-freeing.\n", title.c_str());
    // Will call 'py_unregister_compiled_form()', and thus trim the vector down.
    newref_t unused(PyObject_CallMethod(ref.o, (char *)"Free", "()"));
  }
}
//</code(py_kernwin)>

%}

%{
//<code(py_cli)>
//--------------------------------------------------------------------------
#define MAX_PY_CLI 12

// Callbacks table
// This structure was devised because the cli callbacks have no user-data parameter
struct py_cli_cbs_t
{
  bool (idaapi *execute_line)(const char *line);
  bool (idaapi *complete_line)(
    qstring *completion,
    const char *prefix,
    int n,
    const char *line,
    int x);
  bool (idaapi *keydown)(
    qstring *line,
    int *p_x,
    int *p_sellen,
    int *vk_key,
    int shift);
};

// CLI Python wrapper class
class py_cli_t
{
private:
  //--------------------------------------------------------------------------
  cli_t cli;
  PyObject *self;
  qstring cli_sname, cli_lname, cli_hint;

  //--------------------------------------------------------------------------
  static py_cli_t *py_clis[MAX_PY_CLI];
  static const py_cli_cbs_t py_cli_cbs[MAX_PY_CLI];
  //--------------------------------------------------------------------------
#define IMPL_PY_CLI_CB(CBN)                                             \
  static bool idaapi s_keydown##CBN(qstring *line, int *p_x, int *p_sellen, int *vk_key, int shift) \
  {                                                                     \
    return py_clis[CBN]->on_keydown(line, p_x, p_sellen, vk_key, shift); \
  }                                                                     \
  static bool idaapi s_execute_line##CBN(const char *line)              \
  {                                                                     \
    return py_clis[CBN]->on_execute_line(line);                         \
  }                                                                     \
  static bool idaapi s_complete_line##CBN(qstring *completion, const char *prefix, int n, const char *line, int x) \
  {                                                                     \
    return py_clis[CBN]->on_complete_line(completion, prefix, n, line, x); \
  }

  IMPL_PY_CLI_CB(0);    IMPL_PY_CLI_CB(1);   IMPL_PY_CLI_CB(2);   IMPL_PY_CLI_CB(3);
  IMPL_PY_CLI_CB(4);    IMPL_PY_CLI_CB(5);   IMPL_PY_CLI_CB(6);   IMPL_PY_CLI_CB(7);
  IMPL_PY_CLI_CB(8);    IMPL_PY_CLI_CB(9);   IMPL_PY_CLI_CB(10);  IMPL_PY_CLI_CB(11);
#undef IMPL_PY_CLI_CB

  //--------------------------------------------------------------------------
  // callback: the user pressed Enter
  // CLI is free to execute the line immediately or ask for more lines
  // Returns: true-executed line, false-ask for more lines
  bool on_execute_line(const char *line)
  {
    PYW_GIL_GET;
    newref_t result(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_EXECUTE_LINE,
                    "s",
                    line));
    PyW_ShowCbErr(S_ON_EXECUTE_LINE);
    return result != NULL && PyObject_IsTrue(result.o);
  }

  //--------------------------------------------------------------------------
  // callback: a keyboard key has been pressed
  // This is a generic callback and the CLI is free to do whatever
  // it wants.
  //    line - current input line (in/out argument)
  //    p_x  - pointer to current x coordinate of the cursor (in/out)
  //    p_sellen - pointer to current selection length (usually 0)
  //    p_vk_key - pointer to virtual key code (in/out)
  //           if the key has been handled, it should be reset to 0 by CLI
  //    shift - shift state
  // Returns: true-modified input line or x coordinate or selection length
  // This callback is optional
  bool on_keydown(
    qstring *line,
    int *p_x,
    int *p_sellen,
    int *vk_key,
    int shift)
  {
    PYW_GIL_GET;
    newref_t result(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_KEYDOWN,
                    "siiHi",
                    line->c_str(),
                    *p_x,
                    *p_sellen,
                    *vk_key,
                    shift));

    bool ok = result != NULL && PyTuple_Check(result.o);

    PyW_ShowCbErr(S_ON_KEYDOWN);

    if ( ok )
    {
      Py_ssize_t sz = PyTuple_Size(result.o);
      PyObject *item;

#define GET_TUPLE_ENTRY(col, PyThingy, AsThingy, out)                   \
      do                                                                \
      {                                                                 \
        if ( sz > col )                                                 \
        {                                                               \
          borref_t _r(PyTuple_GetItem(result.o, col));                  \
          if ( _r != NULL && PyThingy##_Check(_r.o) )                   \
            *out = PyThingy##_##AsThingy(_r.o);                         \
        }                                                               \
      } while ( false )

      GET_TUPLE_ENTRY(0, PyString, AsString, line);
      GET_TUPLE_ENTRY(1, PyInt, AsLong, p_x);
      GET_TUPLE_ENTRY(2, PyInt, AsLong, p_sellen);
      GET_TUPLE_ENTRY(3, PyInt, AsLong, vk_key);
      *vk_key &= 0xffff;
#undef GET_TUPLE_ENTRY
    }
    return ok;
  }

  // callback: the user pressed Tab
  // Find a completion number N for prefix PREFIX
  // LINE is given as context information. X is the index where PREFIX starts in LINE
  // New prefix should be stored in PREFIX.
  // Returns: true if generated a new completion
  // This callback is optional
  bool on_complete_line(
          qstring *completion,
          const char *prefix,
          int n,
          const char *line,
          int x)
  {
    PYW_GIL_GET;
    newref_t result(
            PyObject_CallMethod(
                    self,
                    (char *)S_ON_COMPLETE_LINE,
                    "sisi",
                    prefix,
                    n,
                    line,
                    x));

    bool ok = result != NULL && PyString_Check(result.o);
    PyW_ShowCbErr(S_ON_COMPLETE_LINE);
    if ( ok )
      *completion = PyString_AsString(result.o);
    return ok;
  }

  // Private ctor (use bind())
  py_cli_t()
  {
  }

public:
  //---------------------------------------------------------------------------
  static int bind(PyObject *py_obj)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();

    int cli_idx;
    // Find an empty slot
    for ( cli_idx = 0; cli_idx < MAX_PY_CLI; ++cli_idx )
    {
      if ( py_clis[cli_idx] == NULL )
        break;
    }
    py_cli_t *py_cli = NULL;
    do
    {
      // No free slots?
      if ( cli_idx >= MAX_PY_CLI )
        break;

      // Create a new instance
      py_cli = new py_cli_t();
      PyObject *attr;

      // Start populating the 'cli' member
      py_cli->cli.size = sizeof(cli_t);

      // Store 'flags'
      {
        ref_t flags_attr(PyW_TryGetAttrString(py_obj, S_FLAGS));
        if ( flags_attr == NULL )
          py_cli->cli.flags = 0;
        else
          py_cli->cli.flags = PyLong_AsLong(flags_attr.o);
      }

      // Store 'sname'
      if ( !PyW_GetStringAttr(py_obj, "sname", &py_cli->cli_sname) )
        break;
      py_cli->cli.sname = py_cli->cli_sname.c_str();

      // Store 'lname'
      if ( !PyW_GetStringAttr(py_obj, "lname", &py_cli->cli_lname) )
        break;
      py_cli->cli.lname = py_cli->cli_lname.c_str();

      // Store 'hint'
      if ( !PyW_GetStringAttr(py_obj, "hint", &py_cli->cli_hint) )
        break;
      py_cli->cli.hint = py_cli->cli_hint.c_str();

      // Store callbacks
      if ( !PyObject_HasAttrString(py_obj, S_ON_EXECUTE_LINE) )
        break;
      py_cli->cli.execute_line  = py_cli_cbs[cli_idx].execute_line;

      py_cli->cli.complete_line = PyObject_HasAttrString(py_obj, S_ON_COMPLETE_LINE) ? py_cli_cbs[cli_idx].complete_line : NULL;
      py_cli->cli.keydown       = PyObject_HasAttrString(py_obj, S_ON_KEYDOWN) ? py_cli_cbs[cli_idx].keydown : NULL;

      // install CLI
      install_command_interpreter(&py_cli->cli);

      // Take reference to this object
      py_cli->self = py_obj;
      Py_INCREF(py_obj);

      // Save the instance
      py_clis[cli_idx] = py_cli;

      return cli_idx;
    } while (false);

    delete py_cli;
    return -1;
  }

  //---------------------------------------------------------------------------
  static void unbind(int cli_idx)
  {
    // Out of bounds or not set?
    if ( cli_idx < 0 || cli_idx >= MAX_PY_CLI || py_clis[cli_idx] == NULL )
      return;

    py_cli_t *py_cli = py_clis[cli_idx];
    remove_command_interpreter(&py_cli->cli);

    {
      PYW_GIL_CHECK_LOCKED_SCOPE();
      Py_DECREF(py_cli->self);
      delete py_cli;
    }

    py_clis[cli_idx] = NULL;

    return;
  }
};
py_cli_t *py_cli_t::py_clis[MAX_PY_CLI] = {NULL};
#define DECL_PY_CLI_CB(CBN) { s_execute_line##CBN, s_complete_line##CBN, s_keydown##CBN }
const py_cli_cbs_t py_cli_t::py_cli_cbs[MAX_PY_CLI] =
{
  DECL_PY_CLI_CB(0),   DECL_PY_CLI_CB(1),  DECL_PY_CLI_CB(2),   DECL_PY_CLI_CB(3),
  DECL_PY_CLI_CB(4),   DECL_PY_CLI_CB(5),  DECL_PY_CLI_CB(6),   DECL_PY_CLI_CB(7),
  DECL_PY_CLI_CB(8),   DECL_PY_CLI_CB(9),  DECL_PY_CLI_CB(10),  DECL_PY_CLI_CB(11)
};
#undef DECL_PY_CLI_CB
//</code(py_cli)>

//<code(py_plgform)>
//---------------------------------------------------------------------------
class plgform_t
{
private:
  ref_t py_obj;
  TForm *form;

  static int idaapi s_callback(void *ud, int notification_code, va_list va)
  {
    // This hook gets called from the kernel. Ensure we hold the GIL.
    PYW_GIL_GET;

    plgform_t *_this = (plgform_t *)ud;
    if ( notification_code == ui_tform_visible )
    {
      TForm *form = va_arg(va, TForm *);
      if ( form == _this->form )
      {
        // Qt: QWidget*
        // G: HWND
        // We wrap and pass as a CObject in the hope that a Python UI framework
        // can unwrap a CObject and get the hwnd/widget back
        newref_t py_result(
                PyObject_CallMethod(
                        _this->py_obj.o,
                        (char *)S_ON_CREATE, "O",
                        PyCObject_FromVoidPtr(form, NULL)));
        PyW_ShowCbErr(S_ON_CREATE);
      }
    }
    else if ( notification_code == ui_tform_invisible )
    {
      TForm *form = va_arg(va, TForm *);
      if ( form == _this->form )
      {
        {
          newref_t py_result(
                  PyObject_CallMethod(
                          _this->py_obj.o,
                          (char *)S_ON_CLOSE, "O",
                          PyCObject_FromVoidPtr(form, NULL)));
          PyW_ShowCbErr(S_ON_CLOSE);
        }
        _this->unhook();
      }
    }
    return 0;
  }

  void unhook()
  {
    unhook_from_notification_point(HT_UI, s_callback, this);
    form = NULL;

    // Call DECREF at last, since it may trigger __del__
    PYW_GIL_CHECK_LOCKED_SCOPE();
    py_obj = ref_t();
  }

public:
  plgform_t(): form(NULL)
  {
  }

  bool show(
    PyObject *obj,
    const char *caption,
    int options)
  {
    // Already displayed?
    TForm *f = find_tform(caption);
    if ( f != NULL )
    {
      // Our form?
      if ( f == form )
      {
        // Switch to it
        switchto_tform(form, true);
        return true;
      }
      // Fail to create
      return false;
    }

    // Create a form
    form = create_tform(caption, NULL);
    if ( form == NULL )
      return false;

    if ( !hook_to_notification_point(HT_UI, s_callback, this) )
    {
      form = NULL;
      return false;
    }

    py_obj = borref_t(obj);

    if ( is_idaq() )
      options |= FORM_QWIDGET;

    this->form = form;
    open_tform(form, options);
    return true;
  }

  void close(int options = 0)
  {
    if ( form != NULL )
      close_tform(form, options);
  }

  static PyObject *create()
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    return PyCObject_FromVoidPtr(new plgform_t(), destroy);
  }

  static void destroy(void *obj)
  {
    delete (plgform_t *)obj;
  }
};
//</code(py_plgform)>
%}

%inline %{
//<inline(py_plgform)>
//---------------------------------------------------------------------------
#define DECL_PLGFORM PYW_GIL_CHECK_LOCKED_SCOPE(); plgform_t *plgform = (plgform_t *) PyCObject_AsVoidPtr(py_link);
static PyObject *plgform_new()
{
  return plgform_t::create();
}

static bool plgform_show(
  PyObject *py_link,
  PyObject *py_obj,
  const char *caption,
  int options = FORM_TAB|FORM_MENU|FORM_RESTORE)
{
  DECL_PLGFORM;
  return plgform->show(py_obj, caption, options);
}

static void plgform_close(
  PyObject *py_link,
  int options)
{
  DECL_PLGFORM;
  plgform->close(options);
}
#undef DECL_PLGFORM
//</inline(py_plgform)>
%}

%{
//<code(py_custviewer)>
//---------------------------------------------------------------------------
// Base class for all custviewer place_t providers
class custviewer_data_t
{
public:
  virtual void    *get_ud() = 0;
  virtual place_t *get_min() = 0;
  virtual place_t *get_max() = 0;
};

//---------------------------------------------------------------------------
class cvdata_simpleline_t: public custviewer_data_t
{
private:
  strvec_t lines;
  simpleline_place_t pl_min, pl_max;
public:

  void *get_ud()
  {
    return &lines;
  }

  place_t *get_min()
  {
    return &pl_min;
  }

  place_t *get_max()
  {
    return &pl_max;
  }

  strvec_t &get_lines()
  {
    return lines;
  }

  void set_minmax(size_t start=0, size_t end=size_t(-1))
  {
    if ( start == 0 && end == size_t(-1) )
    {
      end = lines.size();
      pl_min.n = 0;
      pl_max.n = end == 0 ? 0 : end - 1;
    }
    else
    {
      pl_min.n = start;
      pl_max.n = end;
    }
  }

  bool set_line(size_t nline, simpleline_t &sl)
  {
    if ( nline >= lines.size() )
      return false;
    lines[nline] = sl;
    return true;
  }

  bool del_line(size_t nline)
  {
    if ( nline >= lines.size() )
      return false;
    lines.erase(lines.begin()+nline);
    return true;
  }

  void add_line(simpleline_t &line)
  {
    lines.push_back(line);
  }

  void add_line(const char *str)
  {
    lines.push_back(simpleline_t(str));
  }

  bool insert_line(size_t nline, simpleline_t &line)
  {
    if ( nline >= lines.size() )
      return false;
    lines.insert(lines.begin()+nline, line);
    return true;
  }

  bool patch_line(size_t nline, size_t offs, int value)
  {
    if ( nline >= lines.size() )
      return false;
    qstring &L = lines[nline].line;
    L[offs] = (uchar) value & 0xFF;
    return true;
  }

  const size_t to_lineno(place_t *pl) const
  {
    return ((simpleline_place_t *)pl)->n;
  }

  bool curline(place_t *pl, size_t *n)
  {
    if ( pl == NULL )
      return false;

    *n = to_lineno(pl);
    return true;
  }

  simpleline_t *get_line(size_t nline)
  {
    return nline >= lines.size() ? NULL : &lines[nline];
  }

  simpleline_t *get_line(place_t *pl)
  {
    return pl == NULL ? NULL : get_line(((simpleline_place_t *)pl)->n);
  }

  const size_t count() const
  {
    return lines.size();
  }

  void clear_lines()
  {
    lines.clear();
    set_minmax();
  }
};

//---------------------------------------------------------------------------
// FIXME: This should inherit py_view_base.hpp's py_customidamemo_t,
// just like py_graph.hpp's py_graph_t does.
// There should be a way to "merge" the two mechanisms; they are similar.
class customviewer_t
{
protected:
  qstring _title;
  TForm *_form;
  TCustomControl *_cv;
  custviewer_data_t *_data;
  int _features;
  enum
  {
    HAVE_HINT     = 0x0001,
    HAVE_KEYDOWN  = 0x0002,
    HAVE_POPUP    = 0x0004,
    HAVE_DBLCLICK = 0x0008,
    HAVE_CURPOS   = 0x0010,
    HAVE_CLICK    = 0x0020,
    HAVE_CLOSE    = 0x0040
  };
private:
  struct cvw_popupctx_t
  {
    size_t menu_id;
    customviewer_t *cv;
    cvw_popupctx_t(): menu_id(0), cv(NULL) { }
    cvw_popupctx_t(size_t mid, customviewer_t *v): menu_id(mid), cv(v) { }
  };
  typedef std::map<unsigned int, cvw_popupctx_t> cvw_popupmap_t;
  static cvw_popupmap_t _global_popup_map;
  static size_t _global_popup_id;
  qstring _curline;
  intvec_t _installed_popups;

  static bool idaapi s_popup_menu_cb(void *ud)
  {
    size_t mid = (size_t)ud;
    cvw_popupmap_t::iterator it = _global_popup_map.find(mid);
    if ( it == _global_popup_map.end() )
      return false;

    PYW_GIL_GET;
    return it->second.cv->on_popup_menu(it->second.menu_id);
  }

  static bool idaapi s_cv_keydown(
      TCustomControl * /*cv*/,
      int vk_key,
      int shift,
      void *ud)
  {
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    return _this->on_keydown(vk_key, shift);
  }

  // The popup menu is being constructed
  static void idaapi s_cv_popup(TCustomControl * /*cv*/, void *ud)
  {
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    _this->on_popup();
  }

  // The user clicked
  static bool idaapi s_cv_click(TCustomControl * /*cv*/, int shift, void *ud)
  {
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    return _this->on_click(shift);
  }

  // The user double clicked
  static bool idaapi s_cv_dblclick(TCustomControl * /*cv*/, int shift, void *ud)
  {
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    return _this->on_dblclick(shift);
  }

  // Cursor position has been changed
  static void idaapi s_cv_curpos(TCustomControl * /*cv*/, void *ud)
  {
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    _this->on_curpos_changed();
  }

  //--------------------------------------------------------------------------
  static int idaapi s_ui_cb(void *ud, int code, va_list va)
  {
    // This hook gets called from the kernel. Ensure we hold the GIL.
    PYW_GIL_GET;
    customviewer_t *_this = (customviewer_t *)ud;
    switch ( code )
    {
    case ui_get_custom_viewer_hint:
      {
        TCustomControl *viewer = va_arg(va, TCustomControl *);
        place_t *place         = va_arg(va, place_t *);
        int *important_lines   = va_arg(va, int *);
        qstring &hint          = *va_arg(va, qstring *);
        if ( (_this->_features & HAVE_HINT) == 0 || place == NULL || _this->_cv != viewer )
          return 0;
        else
          return _this->on_hint(place, important_lines, hint) ? 1 : 0;
      }

    case ui_tform_invisible:
      {
        TForm *form = va_arg(va, TForm *);
        if ( _this->_form != form )
          break;
      }
      // fallthrough...
    case ui_term:
      unhook_from_notification_point(HT_UI, s_ui_cb, _this);
      _this->on_close();
      _this->on_post_close();
      break;
    }

    return 0;
  }

  void on_post_close()
  {
    init_vars();
    clear_popup_menu();
  }

public:

  inline TForm *get_tform() { return _form; }
  inline TCustomControl *get_tcustom_control() { return _cv; }

  //
  // All the overridable callbacks
  //

  // OnClick
  virtual bool on_click(int /*shift*/) { return false; }

  // OnDblClick
  virtual bool on_dblclick(int /*shift*/) { return false; }

  // OnCurorPositionChanged
  virtual void on_curpos_changed() { }

  // OnHostFormClose
  virtual void on_close() { }

  // OnKeyDown
  virtual bool on_keydown(int /*vk_key*/, int /*shift*/) { return false; }

  // OnPopupShow
  virtual bool on_popup() { return false; }

  // OnHint
  virtual bool on_hint(place_t * /*place*/, int * /*important_lines*/, qstring &/*hint*/) { return false; }

  // OnPopupMenuClick
  virtual bool on_popup_menu(size_t menu_id) { return false; }

  void init_vars()
  {
    _data = NULL;
    _features = 0;
    _curline.clear();
    _cv = NULL;
    _form = NULL;
  }

  customviewer_t()
  {
    init_vars();
  }

  ~customviewer_t()
  {
  }

  //--------------------------------------------------------------------------
  void close()
  {
    if ( _form != NULL )
      close_tform(_form, FORM_SAVE | FORM_CLOSE_LATER);
  }

  //--------------------------------------------------------------------------
  bool set_range(
    const place_t *minplace = NULL,
    const place_t *maxplace = NULL)
  {
    if ( _cv == NULL )
      return false;

    set_custom_viewer_range(
      _cv,
      minplace == NULL ? _data->get_min() : minplace,
      maxplace == NULL ? _data->get_max() : maxplace);
    return true;
  }

  place_t *get_place(
    bool mouse = false,
    int *x = 0,
    int *y = 0)
  {
    return _cv == NULL ? NULL : get_custom_viewer_place(_cv, mouse, x, y);
  }

  //--------------------------------------------------------------------------
  bool refresh()
  {
    if ( _cv == NULL )
      return false;

    refresh_custom_viewer(_cv);
    return true;
  }

  //--------------------------------------------------------------------------
  bool refresh_current()
  {
    int x, y;
    place_t *pl = get_place(false, &x, &y);
    if ( pl == NULL )
      return false;

    return jumpto(pl, x, y);
  }

  //--------------------------------------------------------------------------
  bool get_current_word(bool mouse, qstring &word)
  {
    // query the cursor position
    int x, y;
    if ( get_place(mouse, &x, &y) == NULL )
      return false;

    // query the line at the cursor
    const char *line = get_current_line(mouse, true);
    if ( line == NULL )
      return false;

    if ( x >= (int)strlen(line) )
      return false;

    // find the beginning of the word
    const char *ptr = line + x;
    while ( ptr > line && !qisspace(ptr[-1]) )
      ptr--;

    // find the end of the word
    const char *begin = ptr;
    ptr = line + x;
    while ( !qisspace(*ptr) && *ptr != '\0' )
      ptr++;

    word.qclear();
    word.append(begin, ptr-begin);
    return true;
  }

  //--------------------------------------------------------------------------
  const char *get_current_line(bool mouse, bool notags)
  {
    const char *r = get_custom_viewer_curline(_cv, mouse);
    if ( r == NULL || !notags )
      return r;

    size_t sz = strlen(r);
    if ( sz == 0 )
      return r;

    _curline.resize(sz + 5, '\0');
    tag_remove(r, &_curline[0], sz + 1);
    return _curline.c_str();
  }

  //--------------------------------------------------------------------------
  bool is_focused()
  {
    return get_current_viewer() == _cv;
  }

  //--------------------------------------------------------------------------
  bool jumpto(place_t *place, int x, int y)
  {
    return ::jumpto(_cv, place, x, y);
  }

  //--------------------------------------------------------------------------
  void clear_popup_menu()
  {
    if ( _cv != NULL )
      set_custom_viewer_popup_menu(_cv, NULL);

    for (intvec_t::iterator it=_installed_popups.begin(), it_end=_installed_popups.end();
         it != it_end;
         ++it)
    {
      _global_popup_map.erase(*it);
    }
    _installed_popups.clear();
  }

  //--------------------------------------------------------------------------
  size_t add_popup_menu(
    const char *title,
    const char *hotkey)
  {
    size_t menu_id = _global_popup_id + 1;

    // Overlap / already exists?
    if (_cv == NULL || // No custviewer?
        // Overlap?
        menu_id == 0 ||
        // Already exists?
        _global_popup_map.find(menu_id) != _global_popup_map.end())
    {
      return 0;
    }
    add_custom_viewer_popup_item(_cv, title, hotkey, s_popup_menu_cb, (void *)menu_id);

    // Save global association
    _global_popup_map[menu_id] = cvw_popupctx_t(menu_id, this);
    _global_popup_id = menu_id;

    // Remember what menu IDs are set with this form
    _installed_popups.push_back(menu_id);
    return menu_id;
  }

  //--------------------------------------------------------------------------
  bool create(const char *title, int features, custviewer_data_t *data)
  {
    // Already created? (in the instance)
    if ( _form != NULL )
      return true;

    // Already created? (in IDA windows list)
    HWND hwnd(NULL);
    TForm *form = create_tform(title, &hwnd);
    if ( hwnd == NULL )
      return false;

    _title    = title;
    _data     = data;
    _form     = form;
    _features = features;

    // Create the viewer
    _cv = create_custom_viewer(
      title,
      (TWinControl *)_form,
      _data->get_min(),
      _data->get_max(),
      _data->get_min(),
      0,
      _data->get_ud());

    // Set user-data
    set_custom_viewer_handler(_cv, CVH_USERDATA, (void *)this);

    //
    // Set other optional callbacks
    //
    if ( (features & HAVE_KEYDOWN) != 0 )
      set_custom_viewer_handler(_cv, CVH_KEYDOWN, (void *)s_cv_keydown);

    if ( (features & HAVE_POPUP) != 0 )
      set_custom_viewer_handler(_cv, CVH_POPUP, (void *)s_cv_popup);

    if ( (features & HAVE_DBLCLICK) != 0 )
      set_custom_viewer_handler(_cv, CVH_DBLCLICK, (void *)s_cv_dblclick);

    if ( (features & HAVE_CURPOS) != 0 )
      set_custom_viewer_handler(_cv, CVH_CURPOS, (void *)s_cv_curpos);

    if ( (features & HAVE_CLICK) != 0 )
      set_custom_viewer_handler(_cv, CVH_CLICK, (void *)s_cv_click);

    // Hook to UI notifications (for TForm close event)
    hook_to_notification_point(HT_UI, s_ui_cb, this);

    return true;
  }

  //--------------------------------------------------------------------------
  bool show()
  {
    // Closed already?
    if ( _form == NULL )
      return false;

    open_tform(_form, FORM_TAB|FORM_MENU|FORM_RESTORE|FORM_QWIDGET);
    return true;
  }
};

customviewer_t::cvw_popupmap_t customviewer_t::_global_popup_map;
size_t customviewer_t::_global_popup_id = 0;
//---------------------------------------------------------------------------
class py_simplecustview_t: public customviewer_t
{
private:
  cvdata_simpleline_t data;
  PyObject *py_self, *py_this, *py_last_link;
  int features;

  //--------------------------------------------------------------------------
  // Convert a tuple (String, [color, [bgcolor]]) to a simpleline_t
  static bool py_to_simpleline(PyObject *py, simpleline_t &sl)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();

    if ( PyString_Check(py) )
    {
      sl.line = PyString_AsString(py);
      return true;
    }
    Py_ssize_t sz;
    if ( !PyTuple_Check(py) || (sz = PyTuple_Size(py)) <= 0 )
      return false;

    PyObject *py_val = PyTuple_GetItem(py, 0);
    if ( !PyString_Check(py_val) )
      return false;

    sl.line = PyString_AsString(py_val);

    if ( (sz > 1) && (py_val = PyTuple_GetItem(py, 1)) && PyLong_Check(py_val)  )
      sl.color = color_t(PyLong_AsUnsignedLong(py_val));

    if ( (sz > 2) && (py_val = PyTuple_GetItem(py, 2)) && PyLong_Check(py_val)  )
      sl.bgcolor = PyLong_AsUnsignedLong(py_val);

    return true;
  }

  //
  // Callbacks
  //
  virtual bool on_click(int shift)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(PyObject_CallMethod(py_self, (char *)S_ON_CLICK, "i", shift));
    PyW_ShowCbErr(S_ON_CLICK);
    return py_result != NULL && PyObject_IsTrue(py_result.o);
  }

  //--------------------------------------------------------------------------
  // OnDblClick
  virtual bool on_dblclick(int shift)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(PyObject_CallMethod(py_self, (char *)S_ON_DBL_CLICK, "i", shift));
    PyW_ShowCbErr(S_ON_DBL_CLICK);
    return py_result != NULL && PyObject_IsTrue(py_result.o);
  }

  //--------------------------------------------------------------------------
  // OnCurorPositionChanged
  virtual void on_curpos_changed()
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(PyObject_CallMethod(py_self, (char *)S_ON_CURSOR_POS_CHANGED, NULL));
    PyW_ShowCbErr(S_ON_CURSOR_POS_CHANGED);
  }

  //--------------------------------------------------------------------------
  // OnHostFormClose
  virtual void on_close()
  {
    // Call the close method if it is there and the object is still bound
    if ( (features & HAVE_CLOSE) != 0 && py_self != NULL )
    {
      PYW_GIL_CHECK_LOCKED_SCOPE();
      newref_t py_result(PyObject_CallMethod(py_self, (char *)S_ON_CLOSE, NULL));
      PyW_ShowCbErr(S_ON_CLOSE);

      // Cleanup
      Py_DECREF(py_self);
      py_self = NULL;
    }
  }

  //--------------------------------------------------------------------------
  // OnKeyDown
  virtual bool on_keydown(int vk_key, int shift)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(
            PyObject_CallMethod(
                    py_self,
                    (char *)S_ON_KEYDOWN,
                    "ii",
                    vk_key,
                    shift));

    PyW_ShowCbErr(S_ON_KEYDOWN);
    return py_result != NULL && PyObject_IsTrue(py_result.o);
  }

  //--------------------------------------------------------------------------
// OnPopupShow
  virtual bool on_popup()
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(
            PyObject_CallMethod(
                    py_self,
                    (char *)S_ON_POPUP,
                    NULL));
    PyW_ShowCbErr(S_ON_POPUP);
    return py_result != NULL && PyObject_IsTrue(py_result.o);
  }

  //--------------------------------------------------------------------------
  // OnHint
  virtual bool on_hint(place_t *place, int *important_lines, qstring &hint)
  {
    size_t ln = data.to_lineno(place);
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(
            PyObject_CallMethod(
                    py_self,
                    (char *)S_ON_HINT,
                    PY_FMT64,
                    pyul_t(ln)));

    PyW_ShowCbErr(S_ON_HINT);
    bool ok = py_result != NULL && PyTuple_Check(py_result.o) && PyTuple_Size(py_result.o) == 2;
    if ( ok )
    {
      if ( important_lines != NULL )
        *important_lines = PyInt_AsLong(PyTuple_GetItem(py_result.o, 0));
      hint = PyString_AsString(PyTuple_GetItem(py_result.o, 1));
    }
    return ok;
  }

  //--------------------------------------------------------------------------
  // OnPopupMenuClick
  virtual bool on_popup_menu(size_t menu_id)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    newref_t py_result(
            PyObject_CallMethod(
                    py_self,
                    (char *)S_ON_POPUP_MENU,
                    PY_FMT64,
                    pyul_t(menu_id)));
    PyW_ShowCbErr(S_ON_POPUP_MENU);
    return py_result != NULL && PyObject_IsTrue(py_result.o);
  }

  //--------------------------------------------------------------------------
  void refresh_range()
  {
    data.set_minmax();
    set_range();
  }

public:
  py_simplecustview_t()
  {
    py_this = py_self = py_last_link = NULL;
  }
  ~py_simplecustview_t()
  {
  }

  //--------------------------------------------------------------------------
  // Edits an existing line
  bool edit_line(size_t nline, PyObject *py_sl)
  {
    simpleline_t sl;
    if ( !py_to_simpleline(py_sl, sl) )
      return false;

    return data.set_line(nline, sl);
  }

  // Low level: patches a line string directly
  bool patch_line(size_t nline, size_t offs, int value)
  {
    return data.patch_line(nline, offs, value);
  }

  // Insert a line
  bool insert_line(size_t nline, PyObject *py_sl)
  {
    simpleline_t sl;
    if ( !py_to_simpleline(py_sl, sl) )
      return false;
    return data.insert_line(nline, sl);
  }

  // Adds a line tuple
  bool add_line(PyObject *py_sl)
  {
    simpleline_t sl;
    if ( !py_to_simpleline(py_sl, sl) )
      return false;
    data.add_line(sl);
    refresh_range();
    return true;
  }

  //--------------------------------------------------------------------------
  bool del_line(size_t nline)
  {
    bool ok = data.del_line(nline);
    if ( ok )
      refresh_range();
    return ok;
  }

  //--------------------------------------------------------------------------
  // Gets the position and returns a tuple (lineno, x, y)
  PyObject *get_pos(bool mouse)
  {
    place_t *pl;
    int x, y;
    pl = get_place(mouse, &x, &y);
    PYW_GIL_CHECK_LOCKED_SCOPE();
    if ( pl == NULL )
      Py_RETURN_NONE;
    return Py_BuildValue("(" PY_FMT64 "ii)", pyul_t(data.to_lineno(pl)), x, y);
  }

  //--------------------------------------------------------------------------
  // Returns the line tuple
  PyObject *get_line(size_t nline)
  {
    simpleline_t *r = data.get_line(nline);
    PYW_GIL_CHECK_LOCKED_SCOPE();
    if ( r == NULL )
      Py_RETURN_NONE;
    return Py_BuildValue("(sII)", r->line.c_str(), (unsigned int)r->color, (unsigned int)r->bgcolor);
  }

  // Returns the count of lines
  const size_t count() const
  {
    return data.count();
  }

  // Clears lines
  void clear()
  {
    data.clear_lines();
    refresh_range();
  }

  //--------------------------------------------------------------------------
  bool jumpto(size_t ln, int x, int y)
  {
    simpleline_place_t l(ln);
    return customviewer_t::jumpto(&l, x, y);
  }

  //--------------------------------------------------------------------------
  // Initializes and links the Python object to this class
  bool init(PyObject *py_link, const char *title)
  {
    // Already created?
    if ( _form != NULL )
      return true;

    // Probe callbacks
    features = 0;
    static struct
    {
      const char *cb_name;
      int feature;
    } const cbtable[] =
    {
      {S_ON_CLICK,              HAVE_CLICK},
      {S_ON_CLOSE,              HAVE_CLOSE},
      {S_ON_HINT,               HAVE_HINT},
      {S_ON_KEYDOWN,            HAVE_KEYDOWN},
      {S_ON_POPUP,              HAVE_POPUP},
      {S_ON_DBL_CLICK,          HAVE_DBLCLICK},
      {S_ON_CURSOR_POS_CHANGED, HAVE_CURPOS}
    };

    PYW_GIL_CHECK_LOCKED_SCOPE();
    for ( size_t i=0; i<qnumber(cbtable); i++ )
    {
      if ( PyObject_HasAttrString(py_link, cbtable[i].cb_name) )
        features |= cbtable[i].feature;
    }

    if ( !create(title, features, &data) )
      return false;

    // Hold a reference to this object
    py_last_link = py_self = py_link;
    Py_INCREF(py_self);

    // Return a reference to the C++ instance (only once)
    if ( py_this == NULL )
      py_this = PyCObject_FromVoidPtr(this, NULL);

    return true;
  }

  //--------------------------------------------------------------------------
  bool show()
  {
    // Form was closed, but object already linked?
    if ( _form == NULL && py_last_link != NULL )
    {
      // Re-create the view (with same previous parameters)
      if ( !init(py_last_link, _title.c_str()) )
        return false;
    }
    return customviewer_t::show();
  }

  //--------------------------------------------------------------------------
  bool get_selection(size_t *x1, size_t *y1, size_t *x2, size_t *y2)
  {
    if ( _cv == NULL )
      return false;

    twinpos_t p1, p2;
    if ( !::readsel2(_cv, &p1, &p2) )
      return false;

    if ( y1 != NULL )
      *y1 = data.to_lineno(p1.at);
    if ( y2 != NULL )
      *y2 = data.to_lineno(p2.at);
    if ( x1 != NULL )
      *x1 = size_t(p1.x);
    if ( x2 != NULL )
      *x2 = p2.x;
    return true;
  }

  PyObject *py_get_selection()
  {
    size_t x1, y1, x2, y2;
    PYW_GIL_CHECK_LOCKED_SCOPE();
    if ( !get_selection(&x1, &y1, &x2, &y2) )
      Py_RETURN_NONE;
    return Py_BuildValue("(" PY_FMT64 PY_FMT64 PY_FMT64 PY_FMT64 ")", pyul_t(x1), pyul_t(y1), pyul_t(x2), pyul_t(y2));
  }

  static py_simplecustview_t *get_this(PyObject *py_this)
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    return PyCObject_Check(py_this) ? (py_simplecustview_t *) PyCObject_AsVoidPtr(py_this) : NULL;
  }

  PyObject *get_pythis()
  {
    return py_this;
  }
};

//</code(py_custviewer)>
%}

%inline %{
//<inline(py_cli)>
static int py_install_command_interpreter(PyObject *py_obj)
{
  return py_cli_t::bind(py_obj);
}

static void py_remove_command_interpreter(int cli_idx)
{
  py_cli_t::unbind(cli_idx);
}
//</inline(py_cli)>

//<inline(py_custviewer)>
//
// Pywraps Simple Custom Viewer functions
//
PyObject *pyscv_init(PyObject *py_link, const char *title)
{
  PYW_GIL_CHECK_LOCKED_SCOPE();
  py_simplecustview_t *_this = new py_simplecustview_t();
  bool ok = _this->init(py_link, title);
  if ( !ok )
  {
    delete _this;
    Py_RETURN_NONE;
  }
  return _this->get_pythis();
}
#define DECL_THIS py_simplecustview_t *_this = py_simplecustview_t::get_this(py_this)

//--------------------------------------------------------------------------
bool pyscv_refresh(PyObject *py_this)
{
  DECL_THIS;
  if ( _this == NULL )
    return false;
  return _this->refresh();
}

//--------------------------------------------------------------------------
bool pyscv_delete(PyObject *py_this)
{
  DECL_THIS;
  if ( _this == NULL )
    return false;
  _this->close();
  delete _this;
  return true;
}

//--------------------------------------------------------------------------
bool pyscv_refresh_current(PyObject *py_this)
{
  DECL_THIS;
  if ( _this == NULL )
    return false;
  return _this->refresh_current();
}

//--------------------------------------------------------------------------
PyObject *pyscv_get_current_line(PyObject *py_this, bool mouse, bool notags)
{
  DECL_THIS;
  PYW_GIL_CHECK_LOCKED_SCOPE();
  const char *line;
  if ( _this == NULL || (line = _this->get_current_line(mouse, notags)) == NULL )
    Py_RETURN_NONE;
  return PyString_FromString(line);
}

//--------------------------------------------------------------------------
bool pyscv_is_focused(PyObject *py_this)
{
  DECL_THIS;
  if ( _this == NULL )
    return false;
  return _this->is_focused();
}

void pyscv_clear_popup_menu(PyObject *py_this)
{
  DECL_THIS;
  if ( _this != NULL )
    _this->clear_popup_menu();
}

size_t pyscv_add_popup_menu(PyObject *py_this, const char *title, const char *hotkey)
{
  DECL_THIS;
  return _this == NULL ? 0 : _this->add_popup_menu(title, hotkey);
}

size_t pyscv_count(PyObject *py_this)
{
  DECL_THIS;
  return _this == NULL ? 0 : _this->count();
}

bool pyscv_show(PyObject *py_this)
{
  DECL_THIS;
  return _this == NULL ? false : _this->show();
}

void pyscv_close(PyObject *py_this)
{
  DECL_THIS;
  if ( _this != NULL )
    _this->close();
}

bool pyscv_jumpto(PyObject *py_this, size_t ln, int x, int y)
{
  DECL_THIS;
  if ( _this == NULL )
    return false;
  return _this->jumpto(ln, x, y);
}

// Returns the line tuple
PyObject *pyscv_get_line(PyObject *py_this, size_t nline)
{
  DECL_THIS;
  if ( _this == NULL )
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    Py_RETURN_NONE;
  }
  return _this->get_line(nline);
}

//--------------------------------------------------------------------------
// Gets the position and returns a tuple (lineno, x, y)
PyObject *pyscv_get_pos(PyObject *py_this, bool mouse)
{
  DECL_THIS;
  if ( _this == NULL )
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    Py_RETURN_NONE;
  }
  return _this->get_pos(mouse);
}

//--------------------------------------------------------------------------
PyObject *pyscv_clear_lines(PyObject *py_this)
{
  DECL_THIS;
  if ( _this != NULL )
    _this->clear();
  PYW_GIL_CHECK_LOCKED_SCOPE();
  Py_RETURN_NONE;
}

//--------------------------------------------------------------------------
// Adds a line tuple
bool pyscv_add_line(PyObject *py_this, PyObject *py_sl)
{
  DECL_THIS;
  return _this == NULL ? false : _this->add_line(py_sl);
}

//--------------------------------------------------------------------------
bool pyscv_insert_line(PyObject *py_this, size_t nline, PyObject *py_sl)
{
  DECL_THIS;
  return _this == NULL ? false : _this->insert_line(nline, py_sl);
}

//--------------------------------------------------------------------------
bool pyscv_patch_line(PyObject *py_this, size_t nline, size_t offs, int value)
{
  DECL_THIS;
  return _this == NULL ? false : _this->patch_line(nline, offs, value);
}

//--------------------------------------------------------------------------
bool pyscv_del_line(PyObject *py_this, size_t nline)
{
  DECL_THIS;
  return _this == NULL ? false : _this->del_line(nline);
}

//--------------------------------------------------------------------------
PyObject *pyscv_get_selection(PyObject *py_this)
{
  DECL_THIS;
  if ( _this == NULL )
  {
    PYW_GIL_CHECK_LOCKED_SCOPE();
    Py_RETURN_NONE;
  }
  return _this->py_get_selection();
}

//--------------------------------------------------------------------------
PyObject *pyscv_get_current_word(PyObject *py_this, bool mouse)
{
  DECL_THIS;
  PYW_GIL_CHECK_LOCKED_SCOPE();
  if ( _this != NULL )
  {
    qstring word;
    if ( _this->get_current_word(mouse, word) )
      return PyString_FromString(word.c_str());
  }
  Py_RETURN_NONE;
}

//--------------------------------------------------------------------------
// Edits an existing line
bool pyscv_edit_line(PyObject *py_this, size_t nline, PyObject *py_sl)
{
  DECL_THIS;
  return _this == NULL ? false : _this->edit_line(nline, py_sl);
}

//-------------------------------------------------------------------------
TForm *pyscv_get_tform(PyObject *py_this)
{
  DECL_THIS;
  return _this == NULL ? NULL : _this->get_tform();
}

//-------------------------------------------------------------------------
TCustomControl *pyscv_get_tcustom_control(PyObject *py_this)
{
  DECL_THIS;
  return _this == NULL ? NULL : _this->get_tcustom_control();
}


#undef DECL_THIS
//</inline(py_custviewer)>
%}

%include "kernwin.hpp"

%template(disasm_text_t) qvector<disasm_line_t>;

%extend action_desc_t {
  action_desc_t(
          const char *name,
          const char *label,
          PyObject *handler,
          const char *shortcut = NULL,
          const char *tooltip = NULL,
          int icon = -1)
  {
    action_desc_t *ad = new action_desc_t();
#define DUPSTR(Prop) ad->Prop = Prop == NULL ? NULL : qstrdup(Prop)
    DUPSTR(name);
    DUPSTR(label);
    DUPSTR(shortcut);
    DUPSTR(tooltip);
#undef DUPSTR
    ad->icon = icon;
    ad->handler = new py_action_handler_t(handler);
    ad->owner = &PLUGIN;
    return ad;
  }

  ~action_desc_t()
  {
    if ( $self->handler != NULL ) // Ownership not taken?
      delete $self->handler;
#define FREESTR(Prop) qfree((char *) $self->Prop)
    FREESTR(name);
    FREESTR(label);
    FREESTR(shortcut);
    FREESTR(tooltip);
#undef FREESTR
    delete $self;
  }
}

//-------------------------------------------------------------------------
uint32 choose_choose(PyObject *self,
    int flags,
    int x0,int y0,
    int x1,int y1,
    int width,
    int deflt,
    int icon);

%extend place_t {
  static idaplace_t *as_idaplace_t(place_t *p) { return (idaplace_t *) p; }
  static enumplace_t *as_enumplace_t(place_t *p) { return (enumplace_t *) p; }
  static structplace_t *as_structplace_t(place_t *p) { return (structplace_t *) p; }
  static simpleline_place_t *as_simpleline_place_t(place_t *p) { return (simpleline_place_t *) p; }
}

%extend twinpos_t {

  %pythoncode {
    def place_as_idaplace_t(self):
        return place_t.as_idaplace_t(self.at)
    def place_as_enumplace_t(self):
        return place_t.as_enumplace_t(self.at)
    def place_as_structplace_t(self):
        return place_t.as_structplace_t(self.at)
    def place_as_simpleline_place_t(self):
        return place_t.as_simpleline_place_t(self.at)

    def place(self, view):
        ptype = get_viewer_place_type(view)
        if ptype == TCCPT_IDAPLACE:
            return self.place_as_idaplace_t()
        elif ptype == TCCPT_ENUMPLACE:
            return self.place_as_enumplace_t()
        elif ptype == TCCPT_STRUCTPLACE:
            return self.place_as_structplace_t()
        elif ptype == TCCPT_SIMPLELINE_PLACE:
            return self.place_as_simpleline_place_t()
        else:
            return self.at
  }
}

%pythoncode %{

#<pycode(py_kernwin)>
DP_LEFT           = 0x0001
DP_TOP            = 0x0002
DP_RIGHT          = 0x0004
DP_BOTTOM         = 0x0008
DP_INSIDE         = 0x0010
# if not before, then it is after
# (use DP_INSIDE | DP_BEFORE to insert a tab before a given tab)
# this flag alone cannot be used to determine orientation
DP_BEFORE         = 0x0020
# used with combination of other flags
DP_TAB            = 0x0040
DP_FLOATING       = 0x0080

# ----------------------------------------------------------------------
def load_custom_icon(file_name=None, data=None, format=None):
    """
    Loads a custom icon and returns an identifier that can be used with other APIs

    If file_name is passed then the other two arguments are ignored.

    @param file_name: The icon file name
    @param data: The icon data
    @param format: The icon data format

    @return: Icon id or 0 on failure.
             Use free_custom_icon() to free it
    """
    if file_name is not None:
       return _idaapi.py_load_custom_icon_fn(file_name)
    elif not (data is None and format is None):
       return _idaapi.py_load_custom_icon_data(data, format)
    else:
      return 0

# ----------------------------------------------------------------------
def asklong(defval, format):
    res, val = _idaapi._asklong(defval, format)

    if res == 1:
        return val
    else:
        return None

# ----------------------------------------------------------------------
def askaddr(defval, format):
    res, ea = _idaapi._askaddr(defval, format)

    if res == 1:
        return ea
    else:
        return None

# ----------------------------------------------------------------------
def askseg(defval, format):
    res, sel = _idaapi._askseg(defval, format)

    if res == 1:
        return sel
    else:
        return None

# ----------------------------------------------------------------------
class action_handler_t:
    def __init__(self):
        pass

    def activate(self, ctx):
	return 0

    def update(self, ctx):
        pass



class Choose2(object):
    """
    Choose2 wrapper class.

    Some constants are defined in this class. Please refer to kernwin.hpp for more information.
    """

    CH_MODAL        = 0x01
    """Modal chooser"""

    CH_MULTI        = 0x02
    """Allow multi selection"""

    CH_MULTI_EDIT   = 0x04
    CH_NOBTNS       = 0x08
    CH_ATTRS        = 0x10
    CH_NOIDB        = 0x20
    """use the chooser even without an open database, same as x0=-2"""
    CH_UTF8         = 0x40
    """string encoding is utf-8"""

    CH_BUILTIN_MASK = 0xF80000

    # column flags (are specified in the widths array)
    CHCOL_PLAIN  =  0x00000000
    CHCOL_PATH   =  0x00010000
    CHCOL_HEX    =  0x00020000
    CHCOL_DEC    =  0x00030000
    CHCOL_FORMAT =  0x00070000


    def __init__(self, title, cols, flags=0, popup_names=None,
                 icon=-1, x1=-1, y1=-1, x2=-1, y2=-1, deflt=-1,
                 embedded=False, width=None, height=None):
        """
        Constructs a chooser window.
        @param title: The chooser title
        @param cols: a list of colums; each list item is a list of two items
            example: [ ["Address", 10 | Choose2.CHCOL_HEX], ["Name", 30 | Choose2.CHCOL_PLAIN] ]
        @param flags: One of CH_XXXX constants
        @param deflt: Default starting item
        @param popup_names: list of new captions to replace this list ["Insert", "Delete", "Edit", "Refresh"]
        @param icon: Icon index (the icon should exist in ida resources or an index to a custom loaded icon)
        @param x1, y1, x2, y2: The default location
        @param embedded: Create as embedded chooser
        @param width: Embedded chooser width
        @param height: Embedded chooser height
        """
        self.title = title
        self.flags = flags
        self.cols = cols
        self.deflt = deflt
        self.popup_names = popup_names
        self.icon = icon
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.embedded = embedded
        if embedded:
	        self.x1 = width
	        self.y1 = height


    def Embedded(self):
        """
        Creates an embedded chooser (as opposed to Show())
        @return: Returns 1 on success
        """
        return _idaapi.choose2_create(self, True)


    def GetEmbSelection(self):
        """
        Returns the selection associated with an embedded chooser

        @return:
            - None if chooser is not embedded
            - A list with selection indices (0-based)
        """
        return _idaapi.choose2_get_embedded_selection(self)


    def Show(self, modal=False):
        """
        Activates or creates a chooser window
        @param modal: Display as modal dialog
        @return: For modal choosers it will return the selected item index (0-based)
        """
        if modal:
            self.flags |= Choose2.CH_MODAL

            # Disable the timeout
            old = _idaapi.set_script_timeout(0)
            n = _idaapi.choose2_create(self, False)
            _idaapi.set_script_timeout(old)

            # Delete the modal chooser instance
            self.Close()

            return n
        else:
            self.flags &= ~Choose2.CH_MODAL
            return _idaapi.choose2_create(self, False)


    def Activate(self):
        """Activates a visible chooser"""
        return _idaapi.choose2_activate(self)


    def Refresh(self):
        """Causes the refresh callback to trigger"""
        return _idaapi.choose2_refresh(self)


    def Close(self):
        """Closes the chooser"""
        return _idaapi.choose2_close(self)


    def AddCommand(self,
                   caption,
                   flags = _idaapi.CHOOSER_POPUP_MENU,
                   menu_index = -1,
                   icon = -1,
				   emb=None):
        """
        Deprecated: Use
          - register_action()
          - attach_action_to_menu()
          - attach_action_to_popup()
        """
        # Use the 'emb' as a sentinel. It will be passed the correct value from the EmbeddedChooserControl
        if self.embedded and ((emb is None) or (emb != 2002)):
            raise RuntimeError("Please add a command through EmbeddedChooserControl.AddCommand()")
        return _idaapi.choose2_add_command(self, caption, flags, menu_index, icon)

    #
    # Implement these methods in the subclass:
    #
#<pydoc>
#    def OnClose(self):
#        """
#        Called when the window is being closed.
#        This callback is mandatory.
#        @return: nothing
#        """
#        pass
#
#    def OnGetLine(self, n):
#        """Called when the chooser window requires lines.
#        This callback is mandatory.
#        @param n: Line number (0-based)
#        @return: The user should return a list with ncols elements.
#            example: a list [col1, col2, col3, ...] describing the n-th line
#        """
#        return ["col1 val", "col2 val"]
#
#    def OnGetSize(self):
#        """Returns the element count.
#        This callback is mandatory.
#        @return: Number of elements
#        """
#        return len(self.the_list)
#
#    def OnEditLine(self, n):
#        """
#        Called when an item is being edited.
#        @param n: Line number (0-based)
#        @return: Nothing
#        """
#        pass
#
#    def OnInsertLine(self):
#        """
#        Called when 'Insert' is selected either via the hotkey or popup menu.
#        @return: Nothing
#        """
#        pass
#
#    def OnSelectLine(self, n):
#        """
#        Called when a line is selected and then Ok or double click was pressed
#        @param n: Line number (0-based)
#        """
#        pass
#
#    def OnSelectionChange(self, sel_list):
#        """
#        Called when the selection changes
#        @param sel_list: A list of selected item indices
#        """
#        pass
#
#    def OnDeleteLine(self, n):
#        """
#        Called when a line is about to be deleted
#        @param n: Line number (0-based)
#        """
#        return self.n
#
#    def OnRefresh(self, n):
#        """
#        Triggered when the 'Refresh' is called from the popup menu item.
#
#        @param n: The currently selected line (0-based) at the time of the refresh call
#        @return: Return the number of elements
#        """
#        return self.n
#
#    def OnRefreshed(self):
#        """
#        Triggered when a refresh happens (for example due to column sorting)
#        @param n: Line number (0-based)
#        @return: Return the number of elements
#        """
#        return self.n
#
#    def OnCommand(self, n, cmd_id):
#        """Return int ; check add_chooser_command()"""
#        return 0
#
#    def OnGetIcon(self, n):
#        """
#        Return icon number for a given item (or -1 if no icon is avail)
#        @param n: Line number (0-based)
#        """
#        return -1
#
#    def OnGetLineAttr(self, n):
#        """
#        Return list [bgcolor, flags=CHITEM_XXXX] or None; check chooser_item_attrs_t
#        @param n: Line number (0-based)
#        """
#        return [0x0, CHITEM_BOLD]
#</pydoc>


#ICON WARNING|QUESTION|INFO|NONE
#AUTOHIDE NONE|DATABASE|REGISTRY|SESSION
#HIDECANCEL
#BUTTON YES|NO|CANCEL "Value|NONE"
#STARTITEM {id:ItemName}
#HELP / ENDHELP
try:
    import types
    from ctypes import *
    # On Windows, we use stdcall

    # Callback for buttons
    # typedef void (idaapi *formcb_t)(TView *fields[], int code);

    _FORMCB_T = WINFUNCTYPE(None, c_void_p, c_int)

    # Callback for form change
    # typedef int (idaapi *formchgcb_t)(int field_id, form_actions_t &fa);
    _FORMCHGCB_T = WINFUNCTYPE(c_int, c_int, c_void_p)
except:
    try:
        _FORMCB_T    = CFUNCTYPE(None, c_void_p, c_int)
        _FORMCHGCB_T = CFUNCTYPE(c_int, c_int, c_void_p)
    except:
        _FORMCHGCB_T = _FORMCB_T = None


# -----------------------------------------------------------------------
# textctrl_info_t clinked object
class textctrl_info_t(py_clinked_object_t):
    """Class representing textctrl_info_t"""

    # Some constants
    TXTF_AUTOINDENT = 0x0001
    """Auto-indent on new line"""
    TXTF_ACCEPTTABS = 0x0002
    """Tab key inserts 'tabsize' spaces"""
    TXTF_READONLY   = 0x0004
    """Text cannot be edited (but can be selected and copied)"""
    TXTF_SELECTED   = 0x0008
    """Shows the field with its text selected"""
    TXTF_MODIFIED   = 0x0010
    """Gets/sets the modified status"""
    TXTF_FIXEDFONT  = 0x0020
    """The control uses IDA's fixed font"""

    def __init__(self, text="", flags=0, tabsize=0):
        py_clinked_object_t.__init__(self)
        if text:
            self.text = text
        if flags:
            self.flags = flags
        if tabsize:
            self.tabsize = tabsize

    def _create_clink(self):
        return _idaapi.textctrl_info_t_create()

    def _del_clink(self, lnk):
        return _idaapi.textctrl_info_t_destroy(lnk)

    def _get_clink_ptr(self):
        return _idaapi.textctrl_info_t_get_clink_ptr(self)

    def assign(self, other):
        """Copies the contents of 'other' to 'self'"""
        return _idaapi.textctrl_info_t_assign(self, other)

    def __set_text(self, s):
        """Sets the text value"""
        return _idaapi.textctrl_info_t_set_text(self, s)

    def __get_text(self):
        """Sets the text value"""
        return _idaapi.textctrl_info_t_get_text(self)

    def __set_flags__(self, flags):
        """Sets the flags value"""
        return _idaapi.textctrl_info_t_set_flags(self, flags)

    def __get_flags__(self):
        """Returns the flags value"""
        return _idaapi.textctrl_info_t_get_flags(self)

    def __set_tabsize__(self, tabsize):
        """Sets the tabsize value"""
        return _idaapi.textctrl_info_t_set_tabsize(self, tabsize)

    def __get_tabsize__(self):
        """Returns the tabsize value"""
        return _idaapi.textctrl_info_t_get_tabsize(self)

    value   = property(__get_text, __set_text)
    """Alias for the text property"""
    text    = property(__get_text, __set_text)
    """Text value"""
    flags   = property(__get_flags__, __set_flags__)
    """Flags value"""
    tabsize = property(__get_tabsize__, __set_tabsize__)

# -----------------------------------------------------------------------
class Form(object):

    FT_ASCII = 'A'
    """Ascii string - char *"""
    FT_SEG = 'S'
    """Segment - sel_t *"""
    FT_HEX = 'N'
    """Hex number - uval_t *"""
    FT_SHEX = 'n'
    """Signed hex number - sval_t *"""
    FT_COLOR = 'K'
    """Color button - bgcolor_t *"""
    FT_ADDR = '$'
    """Address - ea_t *"""
    FT_UINT64 = 'L'
    """default base uint64 - uint64"""
    FT_INT64 = 'l'
    """default base int64 - int64"""
    FT_RAWHEX = 'M'
    """Hex number, no 0x prefix - uval_t *"""
    FT_FILE = 'f'
    """File browse - char * at least QMAXPATH"""
    FT_DEC = 'D'
    """Decimal number - sval_t *"""
    FT_OCT = 'O'
    """Octal number, C notation - sval_t *"""
    FT_BIN = 'Y'
    """Binary number, 0b prefix - sval_t *"""
    FT_CHAR = 'H'
    """Char value -- sval_t *"""
    FT_IDENT = 'I'
    """Identifier - char * at least MAXNAMELEN"""
    FT_BUTTON = 'B'
    """Button - def handler(code)"""
    FT_DIR = 'F'
    """Path to directory - char * at least QMAXPATH"""
    FT_TYPE = 'T'
    """Type declaration - char * at least MAXSTR"""
    _FT_USHORT = '_US'
    """Unsigned short"""
    FT_FORMCHG = '%/'
    """Form change callback - formchgcb_t"""
    FT_ECHOOSER = 'E'
    """Embedded chooser - idaapi.Choose2"""
    FT_MULTI_LINE_TEXT = 't'
    """Multi text control - textctrl_info_t"""
    FT_DROPDOWN_LIST   = 'b'
    """Dropdown list control - Form.DropdownControl"""

    FT_CHKGRP = 'C'
    FT_CHKGRP2= 'c'
    FT_RADGRP = 'R'
    FT_RADGRP2= 'r'

    @staticmethod
    def fieldtype_to_ctype(tp, i64 = False):
        """
        Factory method returning a ctype class corresponding to the field type string
        """
        if tp in (Form.FT_SEG, Form.FT_HEX, Form.FT_RAWHEX, Form.FT_ADDR):
            return c_ulonglong if i64 else c_ulong
        elif tp in (Form.FT_SHEX, Form.FT_DEC, Form.FT_OCT, Form.FT_BIN, Form.FT_CHAR):
            return c_longlong if i64 else c_long
        elif tp == Form.FT_UINT64:
            return c_ulonglong
        elif tp == Form.FT_INT64:
            return c_longlong
        elif tp == Form.FT_COLOR:
            return c_ulong
        elif tp == Form._FT_USHORT:
            return c_ushort
        elif tp in (Form.FT_FORMCHG, Form.FT_ECHOOSER):
            return c_void_p
        else:
            return None


    #
    # Generic argument helper classes
    #
    class NumericArgument(object):
        """
        Argument representing various integer arguments (ushort, uint32, uint64, etc...)
        @param tp: One of Form.FT_XXX
        """
        DefI64 = False
        def __init__(self, tp, value):
            cls = Form.fieldtype_to_ctype(tp, self.DefI64)
            if cls is None:
                raise TypeError("Invalid numeric field type: %s" % tp)
            # Get a pointer type to the ctype type
            self.arg = pointer(cls(value))

        def __set_value(self, v):
            self.arg.contents.value = v
        value = property(lambda self: self.arg.contents.value, __set_value)


    class StringArgument(object):
        """
        Argument representing a character buffer
        """
        def __init__(self, size=None, value=None):
            if size is None:
                raise SyntaxError("The string size must be passed")

            if value is None:
                self.arg = create_string_buffer(size)
            else:
                self.arg = create_string_buffer(value, size)
            self.size = size

        def __set_value(self, v):
            self.arg.value = v
        value = property(lambda self: self.arg.value, __set_value)


    #
    # Base control class
    #
    class Control(object):
        def __init__(self):
            self.id = 0
            """Automatically assigned control ID"""

            self.arg = None
            """Control argument value. This could be one element or a list/tuple (for multiple args per control)"""

            self.form = None
            """Reference to the parent form. It is filled by Form.Add()"""


        def get_tag(self):
            """
            Control tag character. One of Form.FT_XXXX.
            The form class will expand the {} notation and replace them with the tags
            """
            pass

        def get_arg(self):
            """
            Control returns the parameter to be pushed on the stack
            (Of AskUsingForm())
            """
            return self.arg

        def free(self):
            """
            Free the control
            """
            # Release the parent form reference
            self.form = None


    #
    # Label controls
    #
    class LabelControl(Control):
        """
        Base class for static label control
        """
        def __init__(self, tp):
            Form.Control.__init__(self)
            self.tp = tp

        def get_tag(self):
            return '%%%d%s' % (self.id, self.tp)


    class StringLabel(LabelControl):
        """
        String label control
        """
        def __init__(self, value, tp=None, sz=1024):
            """
            Type field can be one of:
            A - ascii string
            T - type declaration
            I - ident
            F - folder
            f - file
            X - command
            """
            if tp is None:
                tp = Form.FT_ASCII
            Form.LabelControl.__init__(self, tp)
            self.size  = sz
            self.arg = create_string_buffer(value, sz)


    class NumericLabel(LabelControl, NumericArgument):
        """
        Numeric label control
        """
        def __init__(self, value, tp=None):
            if tp is None:
                tp = Form.FT_HEX
            Form.LabelControl.__init__(self, tp)
            Form.NumericArgument.__init__(self, tp, value)


    #
    # Group controls
    #
    class GroupItemControl(Control):
        """
        Base class for group control items
        """
        def __init__(self, tag, parent):
            Form.Control.__init__(self)
            self.tag = tag
            self.parent = parent
            # Item position (filled when form is compiled)
            self.pos = 0

        def assign_pos(self):
            self.pos = self.parent.next_child_pos()

        def get_tag(self):
            return "%s%d" % (self.tag, self.id)


    class ChkGroupItemControl(GroupItemControl):
        """
        Checkbox group item control
        """
        def __init__(self, tag, parent):
            Form.GroupItemControl.__init__(self, tag, parent)

        def __get_value(self):
            return (self.parent.value & (1 << self.pos)) != 0

        def __set_value(self, v):
            pv = self.parent.value
            if v:
                pv = pv | (1 << self.pos)
            else:
                pv = pv & ~(1 << self.pos)

            self.parent.value = pv

        checked = property(__get_value, __set_value)
        """Get/Sets checkbox item check status"""


    class RadGroupItemControl(GroupItemControl):
        """
        Radiobox group item control
        """
        def __init__(self, tag, parent):
            Form.GroupItemControl.__init__(self, tag, parent)

        def __get_value(self):
            return self.parent.value == self.pos

        def __set_value(self, v):
            self.parent.value = self.pos

        selected = property(__get_value, __set_value)
        """Get/Sets radiobox item selection status"""


    class GroupControl(Control, NumericArgument):
        """
        Base class for group controls
        """
        def __init__(self, children_names, tag, value=0):
            Form.Control.__init__(self)
            self.children_names = children_names
            self.tag = tag
            self._reset()
            Form.NumericArgument.__init__(self, Form._FT_USHORT, value)

        def _reset(self):
            self.childpos = 0

        def next_child_pos(self):
            v = self.childpos
            self.childpos += 1
            return v

        def get_tag(self):
            return "%d" % self.id


    class ChkGroupControl(GroupControl):
        """
        Checkbox group control class.
        It holds a set of checkbox controls
        """
        ItemClass = None
        """
        Group control item factory class instance
        We need this because later we won't be treating ChkGroupControl or RadGroupControl
        individually, instead we will be working with GroupControl in general.
        """
        def __init__(self, children_names, value=0, secondary=False):
            # Assign group item factory class
            if Form.ChkGroupControl.ItemClass is None:
                Form.ChkGroupControl.ItemClass = Form.ChkGroupItemControl

            Form.GroupControl.__init__(
                self,
                children_names,
                Form.FT_CHKGRP2 if secondary else Form.FT_CHKGRP,
                value)


    class RadGroupControl(GroupControl):
        """
        Radiobox group control class.
        It holds a set of radiobox controls
        """
        ItemClass = None
        def __init__(self, children_names, value=0, secondary=False):
            """
            Creates a radiogroup control.
            @param children_names: A tuple containing group item names
            @param value: Initial selected radio item
            @param secondory: Allows rendering one the same line as the previous group control.
                              Use this if you have another group control on the same line.
            """
            # Assign group item factory class
            if Form.RadGroupControl.ItemClass is None:
                Form.RadGroupControl.ItemClass = Form.RadGroupItemControl

            Form.GroupControl.__init__(
                self,
                children_names,
                Form.FT_RADGRP2 if secondary else Form.FT_RADGRP,
                value)


    #
    # Input controls
    #
    class InputControl(Control):
        """
        Generic form input control.
        It could be numeric control, string control, directory/file browsing, etc...
        """
        def __init__(self, tp, width, swidth, hlp = None):
            """
            @param width: Display width
            @param swidth: String width
            """
            Form.Control.__init__(self)
            self.tp = tp
            self.width = width
            self.switdh = swidth
            self.hlp = hlp

        def get_tag(self):
            return "%s%d:%s:%s:%s" % (
                self.tp, self.id,
                self.width,
                self.switdh,
                ":" if self.hlp is None else self.hlp)


    class NumericInput(InputControl, NumericArgument):
        """
        A composite class serving as a base numeric input control class
        """
        def __init__(self, tp=None, value=0, width=50, swidth=10, hlp=None):
            if tp is None:
                tp = Form.FT_HEX
            Form.InputControl.__init__(self, tp, width, swidth, hlp)
            Form.NumericArgument.__init__(self, self.tp, value)


    class ColorInput(NumericInput):
        """
        Color button input control
        """
        def __init__(self, value = 0):
            """
            @param value: Initial color value in RGB
            """
            Form.NumericInput.__init__(self, tp=Form.FT_COLOR, value=value)


    class StringInput(InputControl, StringArgument):
        """
        Base string input control class.
        This class also constructs a StringArgument
        """
        def __init__(self,
                     tp=None,
                     width=1024,
                     swidth=40,
                     hlp=None,
                     value=None,
                     size=None):
            """
            @param width: String size. But in some cases it has special meaning. For example in FileInput control.
                          If you want to define the string buffer size then pass the 'size' argument
            @param swidth: Control width
            @param value: Initial value
            @param size: String size
            """
            if tp is None:
                tp = Form.FT_ASCII
            if not size:
                size = width
            Form.InputControl.__init__(self, tp, width, swidth, hlp)
            Form.StringArgument.__init__(self, size=size, value=value)


    class FileInput(StringInput):
        """
        File Open/Save input control
        """
        def __init__(self,
                     width=512,
                     swidth=80,
                     save=False, open=False,
                     hlp=None, value=None):

            if save == open:
                raise ValueError("Invalid mode. Choose either open or save")
            if width < 512:
                raise ValueError("Invalid width. Must be greater than 512.")

            # The width field is overloaded in this control and is used
            # to denote the type of the FileInput dialog (save or load)
            # On the other hand it is passed as is to the StringArgument part
            Form.StringInput.__init__(
                self,
                tp=Form.FT_FILE,
                width="1" if save else "0",
                swidth=swidth,
                hlp=hlp,
                size=width,
                value=value)


    class DirInput(StringInput):
        """
        Directory browsing control
        """
        def __init__(self,
                     width=512,
                     swidth=80,
                     hlp=None,
                     value=None):

            if width < 512:
                raise ValueError("Invalid width. Must be greater than 512.")

            Form.StringInput.__init__(
                self,
                tp=Form.FT_DIR,
                width=width,
                swidth=swidth,
                hlp=hlp,
                size=width,
                value=value)


    class ButtonInput(InputControl):
        """
        Button control.
        A handler along with a 'code' (numeric value) can be associated with the button.
        This way one handler can handle many buttons based on the button code (or in other terms id or tag)
        """
        def __init__(self, handler, code="", swidth="", hlp=None):
            """
            @param handler: Button handler. A callback taking one argument which is the code.
            @param code: A code associated with the button and that is later passed to the handler.
            """
            Form.InputControl.__init__(
                self,
                Form.FT_BUTTON,
                code,
                swidth,
                hlp)
            self.arg = _FORMCB_T(lambda view, code, h=handler: h(code))


    class FormChangeCb(Control):
        """
        Form change handler.
        This can be thought of like a dialog procedure.
        Everytime a form action occurs, this handler will be called along with the control id.
        The programmer can then call various form actions accordingly:
          - EnableField
          - ShowField
          - MoveField
          - GetFieldValue
          - etc...

        Special control IDs: -1 (The form is initialized) and -2 (Ok has been clicked)

        """
        def __init__(self, handler):
            """
            Constructs the handler.
            @param handler: The handler (preferrably a member function of a class derived from the Form class).
            """
            Form.Control.__init__(self)

            # Save the handler
            self.handler = handler

            # Create a callback stub
            # We use this mechanism to create an intermediate step
            # where we can create an 'fa' adapter for use by Python
            self.arg = _FORMCHGCB_T(self.helper_cb)

        def helper_cb(self, fid, p_fa):
            # Remember the pointer to the forms_action in the parent form
            self.form.p_fa = p_fa

            # Call user's handler
            r = self.handler(fid)
            return 0 if r is None else r

        def get_tag(self):
            return Form.FT_FORMCHG

        def free(self):
            Form.Control.free(self)
            # Remove reference to the handler
            # (Normally the handler is a member function in the parent form)
            self.handler = None


    class EmbeddedChooserControl(InputControl):
        """
        Embedded chooser control.
        This control links to a Chooser2 control created with the 'embedded=True'
        """
        def __init__(self,
                     chooser=None,
                     swidth=40,
                     hlp=None):
            """
            Embedded chooser control

            @param chooser: A chooser2 instance (must be constructed with 'embedded=True')
            """

            # !! Make sure a chooser instance is passed !!
            if chooser is None or not isinstance(chooser, Choose2):
                raise ValueError("Invalid chooser passed.")

            # Create an embedded chooser structure from the Choose2 instance
            if chooser.Embedded() != 1:
                raise ValueError("Failed to create embedded chooser instance.")

            # Construct input control
            Form.InputControl.__init__(self, Form.FT_ECHOOSER, "", swidth)

            # Get a pointer to the chooser_info_t and the selection vector
            # (These two parameters are the needed arguments for the AskUsingForm())
            emb, sel = _idaapi.choose2_get_embedded(chooser)

            # Get a pointer to a c_void_p constructed from an address
            p_embedded = pointer(c_void_p.from_address(emb))
            p_sel      = pointer(c_void_p.from_address(sel))

            # - Create the embedded chooser info on control creation
            # - Do not free the embeded chooser because after we get the args
            #   via Compile() the user can still call Execute() which relies
            #   on the already computed args
            self.arg   = (p_embedded, p_sel)

            # Save chooser instance
            self.chooser = chooser

            # Add a bogus 'size' attribute
            self.size = 0


        value = property(lambda self: self.chooser)
        """Returns the embedded chooser instance"""


        def AddCommand(self,
                       caption,
                       flags = _idaapi.CHOOSER_POPUP_MENU,
                       menu_index = -1,
                       icon = -1):
            """
            Adds a new embedded chooser command
            Save the returned value and later use it in the OnCommand handler

            @return: Returns a negative value on failure or the command index
            """
            if not self.form.title:
                raise ValueError("Form title is not set!")

            # Encode all information for the AddCommand() in the 'caption' parameter
            caption = "%s:%d:%s" % (self.form.title, self.id, caption)
            return self.chooser.AddCommand(caption, flags=flags, menu_index=menu_index, icon=icon, emb=2002)


        def free(self):
            """
            Frees the embedded chooser data
            """
            self.chooser.Close()
            self.chooser = None
            Form.Control.free(self)


    class DropdownListControl(InputControl, _qstrvec_t):
        """
        Dropdown control
        This control allows manipulating a dropdown control
        """
        def __init__(self, items=[], readonly=True, selval=0, width=50, swidth=50, hlp = None):
            """
            @param items: A string list of items used to prepopulate the control
            @param readonly: Specifies whether the dropdown list is editable or not
            @param selval: The preselected item index (when readonly) or text value (when editable)
            @param width: the control width (n/a if the dropdown list is readonly)
            @param swidth: string width
            """

            # Ignore the width if readonly was set
            if readonly:
                width = 0

            # Init the input control base class
            Form.InputControl.__init__(
                self,
                Form.FT_DROPDOWN_LIST,
                width,
                swidth,
                hlp)

            # Init the associated qstrvec
            _qstrvec_t.__init__(self, items)

            # Remember if readonly or not
            self.readonly = readonly

            if readonly:
                # Create a C integer and remember it
                self.__selval = c_int(selval)
                val_addr      = addressof(self.__selval)
            else:
                # Create an strvec with one qstring
                self.__selval = _qstrvec_t([selval])
                # Get address of the first element
                val_addr      = self.__selval.addressof(0)

            # Two arguments:
            # - argument #1: a pointer to the qstrvec containing the items
            # - argument #2: an integer to hold the selection
            #         or
            #            #2: a qstring to hold the dropdown text control value
            self.arg = (
                pointer(c_void_p.from_address(self.clink_ptr)),
                pointer(c_void_p.from_address(val_addr))
            )


        def __set_selval(self, val):
            if self.readonly:
                self.__selval.value = val
            else:
                self.__selval[0] = val

        def __get_selval(self):
            # Return the selection index
            # or the entered text value
            return self.__selval.value if self.readonly else self.__selval[0]

        value  = property(__get_selval, __set_selval)
        selval = property(__get_selval, __set_selval)
        """
        Read/write the selection value.
        The value is used as an item index in readonly mode or text value in editable mode
        This value can be used only after the form has been closed.
        """

        def free(self):
            self._free()


        def set_items(self, items):
            """Sets the dropdown list items"""
            self.from_list(items)


    class MultiLineTextControl(InputControl, textctrl_info_t):
        """
        Multi line text control.
        This class inherits from textctrl_info_t. Thus the attributes are also inherited
        This control allows manipulating a multilinetext control
        """
        def __init__(self, text="", flags=0, tabsize=0, width=50, swidth=50, hlp = None):
            """
            @param text: Initial text value
            @param flags: One of textctrl_info_t.TXTF_.... values
            @param tabsize: Tab size
            @param width: Display width
            @param swidth: String width
            """
            # Init the input control base class
            Form.InputControl.__init__(self, Form.FT_MULTI_LINE_TEXT, width, swidth, hlp)

            # Init the associated textctrl_info base class
            textctrl_info_t.__init__(self, text=text, flags=flags, tabsize=tabsize)

            # Get the argument as a pointer from the embedded ti
            self.arg = pointer(c_void_p.from_address(self.clink_ptr))


        def free(self):
            self._free()


    #
    # Form class
    #
    def __init__(self, form, controls):
        """
        Contruct a Form class.
        This class wraps around AskUsingForm() or OpenForm() and provides an easier / alternative syntax for describing forms.
        The form control names are wrapped inside the opening and closing curly braces and the control themselves are
        defined and instantiated via various form controls (subclasses of Form).

        @param form: The form string
        @param controls: A dictionary containing the control name as a _key_ and control object as _value_
        """
        self._reset()
        self.form = form
        """Form string"""
        self.controls = controls
        """Dictionary of controls"""
        self.__args = None

        self.title = None
        """The Form title. It will be filled when the form is compiled"""

        self.modal = True
        """By default, forms are modal"""

        self.openform_flags = 0
        """
        If non-modal, these flags will be passed to OpenForm.
        This is an OR'ed combination of the PluginForm.FORM_* values.
        """


    def Free(self):
        """
        Frees all resources associated with a compiled form.
        Make sure you call this function when you finish using the form.
        """

        # Free all the controls
        for ctrl in self.__controls.values():
             ctrl.free()

        # Reset the controls
        # (Note that we are not removing the form control attributes, no need)
        self._reset()

        # Unregister, so we don't try and free it again at closing-time.
        _idaapi.py_unregister_compiled_form(self)


    def _reset(self):
        """
        Resets the Form class state variables
        """
        self.__controls = {}
        self.__ctrl_id = 1


    def __getitem__(self, name):
        """Returns a control object by name"""
        return self.__controls[name]


    def Add(self, name, ctrl, mkattr = True):
        """
        Low level function. Prefer AddControls() to this function.
        This function adds one control to the form.

        @param name: Control name
        @param ctrl: Control object
        @param mkattr: Create control name / control object as a form attribute
        """
        # Assign a unique ID
        ctrl.id = self.__ctrl_id
        self.__ctrl_id += 1

        # Create attribute with control name
        if mkattr:
            setattr(self, name, ctrl)

        # Remember the control
        self.__controls[name] = ctrl

        # Link the form to the control via its form attribute
        ctrl.form = self

        # Is it a group? Add each child
        if isinstance(ctrl, Form.GroupControl):
            self._AddGroup(ctrl, mkattr)


    def FindControlById(self, id):
        """
        Finds a control instance given its id
        """
        for ctrl in self.__controls.values():
            if ctrl.id == id:
                return ctrl
        return None


    @staticmethod
    def _ParseFormTitle(form):
        """
        Parses the form's title from the form text
        """
        help_state = 0
        for i, line in enumerate(form.split("\n")):
            if line.startswith("STARTITEM ") or line.startswith("BUTTON "):
                continue
            # Skip "HELP" and remember state
            elif help_state == 0 and line == "HELP":
                help_state = 1 # Mark inside HELP
                continue
            elif help_state == 1 and line == "ENDHELP":
                help_state = 2 # Mark end of HELP
                continue
            return line.strip()

        return None


    def _AddGroup(self, Group, mkattr=True):
        """
        Internal function.
        This function expands the group item names and creates individual group item controls

        @param Group: The group class (checkbox or radio group class)
        """

        # Create group item controls for each child
        for child_name in Group.children_names:
            self.Add(
                child_name,
                # Use the class factory
                Group.ItemClass(Group.tag, Group),
                mkattr)


    def AddControls(self, controls, mkattr=True):
        """
        Adds controls from a dictionary.
        The dictionary key is the control name and the value is a Form.Control object
        @param controls: The control dictionary
        """
        for name, ctrl in controls.items():
            # Add the control
            self.Add(name, ctrl, mkattr)


    def CompileEx(self, form):
        """
        Low level function.
        Compiles (parses the form syntax and adds the control) the form string and
        returns the argument list to be passed the argument list to AskUsingForm().

        The form controls are wrapped inside curly braces: {ControlName}.

        A special operator can be used to return the ID of a given control by its name: {id:ControlName}.
        This is useful when you use the STARTITEM form keyword to set the initially focused control.

        @param form: Compiles the form and returns the arguments needed to be passed to AskUsingForm()
        """
        # First argument is the form string
        args = [None]

        # Second argument, if form is not modal, is the set of flags
        if not self.modal:
            args.append(self.openform_flags | 0x80) # Add FORM_QWIDGET

        ctrlcnt = 1

        # Reset all group control internal flags
        for ctrl in self.__controls.values():
            if isinstance(ctrl, Form.GroupControl):
                ctrl._reset()

        p = 0
        while True:
            i1 = form.find("{", p)
            # No more items?
            if i1 == -1:
                break

            # Check if escaped
            if (i1 != 0) and form[i1-1] == "\\":
                # Remove escape sequence and restart search
                form = form[:i1-1] + form[i1:]

                # Skip current marker
                p = i1

                # Continue search
                continue

            i2 = form.find("}", i1)
            if i2 == -1:
                raise SyntaxError("No matching closing brace '}'")

            # Parse control name
            ctrlname = form[i1+1:i2]
            if not ctrlname:
                raise ValueError("Control %d has an invalid name!" % ctrlcnt)

            # Is it the IDOF operator?
            if ctrlname.startswith("id:"):
                idfunc = True
                # Take actual ctrlname
                ctrlname = ctrlname[3:]
            else:
                idfunc = False

            # Find the control
            ctrl = self.__controls.get(ctrlname, None)
            if ctrl is None:
                raise ValueError("No matching control '%s'" % ctrlname)

            # Replace control name by tag
            if idfunc:
                tag = str(ctrl.id)
            else:
                tag = ctrl.get_tag()
            taglen = len(tag)
            form = form[:i1] + tag + form[i2+1:]

            # Set new position
            p = i1 + taglen

            # Was it an IDOF() ? No need to push parameters
            # Just ID substitution is fine
            if idfunc:
                continue


            # For GroupItem controls, there are no individual arguments
            # The argument is assigned for the group itself
            if isinstance(ctrl, Form.GroupItemControl):
                # GroupItem controls will have their position dynamically set
                ctrl.assign_pos()
            else:
                # Push argument(s)
                # (Some controls need more than one argument)
                arg = ctrl.get_arg()
                if isinstance(arg, (types.ListType, types.TupleType)):
                    # Push all args
                    args.extend(arg)
                else:
                    # Push one arg
                    args.append(arg)

            ctrlcnt += 1

        # If no FormChangeCb instance was passed, and thus there's no '%/'
        # in the resulting form string, let's provide a minimal one, so that
        # we will retrieve 'p_fa', and thus actions that rely on it will work.
        if form.find(Form.FT_FORMCHG) < 0:
            form = form + Form.FT_FORMCHG
            fccb = Form.FormChangeCb(lambda *args: 1)
            self.Add("___dummyfchgcb", fccb)
            # Regardless of the actual position of '%/' in the form
            # string, a formchange callback _must_ be right after
            # the form string.
            if self.modal:
                inspos = 1
            else:
                inspos = 2
            args.insert(inspos, fccb.get_arg())

        # Patch in the final form string
        args[0] = form

        self.title = self._ParseFormTitle(form)
        return args


    def Compile(self):
        """
        Compiles a form and returns the form object (self) and the argument list.
        The form object will contain object names corresponding to the form elements

        @return: It will raise an exception on failure. Otherwise the return value is ignored
        """

        # Reset controls
        self._reset()

        # Insert controls
        self.AddControls(self.controls)

        # Compile form and get args
        self.__args = self.CompileEx(self.form)

        # Register this form, to make sure it will be freed at closing-time.
        _idaapi.py_register_compiled_form(self)

        return (self, self.__args)


    def Compiled(self):
        """
        Checks if the form has already been compiled

        @return: Boolean
        """
        return self.__args is not None


    def _ChkCompiled(self):
        if not self.Compiled():
            raise SyntaxError("Form is not compiled")


    def Execute(self):
        """
        Displays a modal dialog containing the compiled form.
        @return: 1 - ok ; 0 - cancel
        """
        self._ChkCompiled()
        if not self.modal:
            raise SyntaxError("Form is not modal. Open() should be instead")

        return AskUsingForm(*self.__args)


    def Open(self):
        """
        Opens a widget containing the compiled form.
        """
        self._ChkCompiled()
        if self.modal:
            raise SyntaxError("Form is modal. Execute() should be instead")

        OpenForm(*self.__args)


    def EnableField(self, ctrl, enable):
        """
        Enable or disable an input field
        @return: False - no such control
        """
        return _idaapi.formchgcbfa_enable_field(self.p_fa, ctrl.id, enable)


    def ShowField(self, ctrl, show):
        """
        Show or hide an input field
        @return: False - no such control
        """
        return _idaapi.formchgcbfa_show_field(self.p_fa, ctrl.id, show)


    def MoveField(self, ctrl, x, y, w, h):
        """
        Move/resize an input field

        @return: False - no such fiel
        """
        return _idaapi.formchgcbfa_move_field(self.p_fa, ctrl.id, x, y, w, h)


    def GetFocusedField(self):
        """
        Get currently focused input field.
        @return: None if no field is selected otherwise the control ID
        """
        id = _idaapi.formchgcbfa_get_focused_field(self.p_fa)
        return self.FindControlById(id)


    def SetFocusedField(self, ctrl):
        """
        Set currently focused input field
        @return: False - no such control
        """
        return _idaapi.formchgcbfa_set_focused_field(self.p_fa, ctrl.id)


    def RefreshField(self, ctrl):
        """
        Refresh a field
        @return: False - no such control
        """
        return _idaapi.formchgcbfa_refresh_field(self.p_fa, ctrl.id)


    def Close(self, close_normally):
        """
        Close the form
        @param close_normally:
                   1: form is closed normally as if the user pressed Enter
                   0: form is closed abnormally as if the user pressed Esc
        @return: None
        """
        return _idaapi.formchgcbfa_close(self.p_fa, close_normally)


    def GetControlValue(self, ctrl):
        """
        Returns the control's value depending on its type
        @param ctrl: Form control instance
        @return:
            - color button, radio controls: integer
            - file/dir input, string input and string label: string
            - embedded chooser control (0-based indices of selected items): integer list
            - for multilinetext control: textctrl_info_t
            - dropdown list controls: string (when editable) or index (when readonly)
            - None: on failure
        """
        tid, sz = self.ControlToFieldTypeIdAndSize(ctrl)
        r = _idaapi.formchgcbfa_get_field_value(
                    self.p_fa,
                    ctrl.id,
                    tid,
                    sz)
        # Multilinetext? Unpack the tuple into a new textctrl_info_t instance
        if r is not None and tid == 7:
            return textctrl_info_t(text=r[0], flags=r[1], tabsize=r[2])
        else:
            return r


    def SetControlValue(self, ctrl, value):
        """
        Set the control's value depending on its type
        @param ctrl: Form control instance
        @param value:
            - embedded chooser: a 0-base indices list to select embedded chooser items
            - multilinetext: a textctrl_info_t
            - dropdown list: an integer designating the selection index if readonly
                             a string designating the edit control value if not readonly
        @return: Boolean true on success
        """
        tid, _ = self.ControlToFieldTypeIdAndSize(ctrl)
        return _idaapi.formchgcbfa_set_field_value(
                    self.p_fa,
                    ctrl.id,
                    tid,
                    value)


    @staticmethod
    def ControlToFieldTypeIdAndSize(ctrl):
        """
        Converts a control object to a tuple containing the field id
        and the associated buffer size
        """
        # Input control depend on the associated buffer size (supplied by the user)

        # Make sure you check instances types taking into account inheritance
        if isinstance(ctrl, Form.DropdownListControl):
            return (8, 1 if ctrl.readonly else 0)
        elif isinstance(ctrl, Form.MultiLineTextControl):
            return (7, 0)
        elif isinstance(ctrl, Form.EmbeddedChooserControl):
            return (5, 0)
        # Group items or controls
        elif isinstance(ctrl, (Form.GroupItemControl, Form.GroupControl)):
            return (2, 0)
        elif isinstance(ctrl, Form.StringLabel):
            return (3, min(_idaapi.MAXSTR, ctrl.size))
        elif isinstance(ctrl, Form.ColorInput):
            return (4, 0)
        elif isinstance(ctrl, Form.NumericInput):
            # Pass the numeric control type
            return (6, ord(ctrl.tp[0]))
        elif isinstance(ctrl, Form.InputControl):
            return (1, ctrl.size)
        else:
            raise NotImplementedError, "Not yet implemented"

# --------------------------------------------------------------------------
# Instantiate AskUsingForm function pointer
try:
    import ctypes
    # Setup the numeric argument size
    Form.NumericArgument.DefI64 = _idaapi.BADADDR == 0xFFFFFFFFFFFFFFFFL
    AskUsingForm__ = ctypes.CFUNCTYPE(ctypes.c_long)(_idaapi.py_get_AskUsingForm())
    OpenForm__ = ctypes.CFUNCTYPE(ctypes.c_long)(_idaapi.py_get_OpenForm())
except:
    def AskUsingForm__(*args):
        warning("AskUsingForm() needs ctypes library in order to work")
        return 0
    def OpenForm__(*args):
        warning("OpenForm() needs ctypes library in order to work")


def AskUsingForm(*args):
    """
    Calls AskUsingForm()
    @param: Compiled Arguments obtain through the Form.Compile() function
    @return: 1 = ok, 0 = cancel
    """
    old = set_script_timeout(0)
    r = AskUsingForm__(*args)
    set_script_timeout(old)
    return r

def OpenForm(*args):
    """
    Calls OpenForm()
    @param: Compiled Arguments obtain through the Form.Compile() function
    """
    old = set_script_timeout(0)
    r = OpenForm__(*args)
    set_script_timeout(old)


#</pycode(py_kernwin)>

#<pycode(py_plgform)>
class PluginForm(object):
    """
    PluginForm class.

    This form can be used to host additional controls. Please check the PyQt example.
    """

    FORM_MDI      = 0x01
    """start by default as MDI (obsolete)"""
    FORM_TAB      = 0x02
    """attached by default to a tab"""
    FORM_RESTORE  = 0x04
    """restore state from desktop config"""
    FORM_ONTOP    = 0x08
    """form should be "ontop"""
    FORM_MENU     = 0x10
    """form must be listed in the windows menu (automatically set for all plugins)"""
    FORM_CENTERED = 0x20
    """form will be centered on the screen"""
    FORM_PERSIST  = 0x40
    """form will persist until explicitly closed with Close()"""


    def __init__(self):
        """
        """
        self.__clink__ = _idaapi.plgform_new()



    def Show(self, caption, options = 0):
        """
		Creates the form if not was not created or brings to front if it was already created

        @param caption: The form caption
        @param options: One of PluginForm.FORM_ constants
        """
        options |= PluginForm.FORM_TAB|PluginForm.FORM_MENU|PluginForm.FORM_RESTORE
        return _idaapi.plgform_show(self.__clink__, self, caption, options)


    @staticmethod
    def FormToPyQtWidget(form, ctx = sys.modules['__main__']):
        """
        Use this method to convert a TForm* to a QWidget to be used by PyQt

        @param ctx: Context. Reference to a module that already imported SIP and QtGui modules
        """
        return ctx.sip.wrapinstance(ctx.sip.voidptr(form).__int__(), ctx.QtGui.QWidget)


    @staticmethod
    def FormToPySideWidget(form, ctx = sys.modules['__main__']):
        """
        Use this method to convert a TForm* to a QWidget to be used by PySide

        @param ctx: Context. Reference to a module that already imported QtGui module
        """
        if form is None:
            return None
        if type(form).__name__ == "SwigPyObject":
            # Since 'form' is a SwigPyObject, we first need to convert it to a PyCObject.
            # However, there's no easy way of doing it, so we'll use a rather brutal approach:
            # converting the SwigPyObject to a 'long' (will go through 'SwigPyObject_long',
            # that will return the pointer's value as a long), and then convert that value
            # back to a pointer into a PyCObject.
            ptr_l = long(form)
            from ctypes import pythonapi, c_void_p, py_object
            pythonapi.PyCObject_FromVoidPtr.restype  = py_object
            pythonapi.PyCObject_AsVoidPtr.argtypes = [c_void_p, c_void_p]
            form = pythonapi.PyCObject_FromVoidPtr(ptr_l, 0)
        return ctx.QtGui.QWidget.FromCObject(form)


    def OnCreate(self, form):
        """
        This event is called when the plugin form is created.
        The programmer should populate the form when this event is triggered.

        @return: None
        """
        pass


    def OnClose(self, form):
        """
        Called when the plugin form is closed

        @return: None
        """
        pass


    def Close(self, options):
        """
        Closes the form.

        @param options: Close options (FORM_SAVE, FORM_NO_CONTEXT, ...)

        @return: None
        """
        return _idaapi.plgform_close(self.__clink__, options)

    FORM_SAVE           = 0x1
    """Save state in desktop config"""

    FORM_NO_CONTEXT     = 0x2
    """Don't change the current context (useful for toolbars)"""

    FORM_DONT_SAVE_SIZE = 0x4
    """Don't save size of the window"""

    FORM_CLOSE_LATER    = 0x8
    """This flag should be used when Close() is called from an event handler"""
#</pycode(py_plgform)>

class Choose:
  """
  Choose - class for choose() with callbacks
  """
  def __init__(self, list, title, flags=0, deflt=1, icon=37):
    self.list = list
    self.title = title

    self.flags = flags
    self.x0 = -1
    self.x1 = -1
    self.y0 = -1
    self.y1 = -1

    self.width = -1
    self.deflt = deflt
    self.icon = icon

    # HACK: Add a circular reference for non-modal choosers. This prevents the GC
    # from collecting the class object the callbacks need. Unfortunately this means
    # that the class will never be collected, unless refhack is set to None explicitly.
    if (flags & Choose2.CH_MODAL) == 0:
      self.refhack = self

  def sizer(self):
    """
    Callback: sizer - returns the length of the list
    """
    return len(self.list)

  def getl(self, n):
    """
    Callback: getl - get one item from the list
    """
    if n == 0:
       return self.title
    if n <= self.sizer():
      return str(self.list[n-1])
    else:
      return "<Empty>"


  def ins(self):
    pass


  def update(self, n):
    pass


  def edit(self, n):
    pass


  def enter(self, n):
    print "enter(%d) called" % n


  def destroy(self):
    pass


  def get_icon(self, n):
    pass


  def choose(self):
    """
    choose - Display the choose dialogue
    """
    old = set_script_timeout(0)
    n = _idaapi.choose_choose(
        self,
        self.flags,
        self.x0,
        self.y0,
        self.x1,
        self.y1,
        self.width,
        self.deflt,
        self.icon)
    set_script_timeout(old)
    return n
%}

%pythoncode %{
#<pycode(py_cli)>
class cli_t(pyidc_opaque_object_t):
    """
    cli_t wrapper class.

    This class allows you to implement your own command line interface handlers.
    """

    def __init__(self):
        self.__cli_idx = -1
        self.__clink__ = None


    def register(self, flags = 0, sname = None, lname = None, hint = None):
        """
        Registers the CLI.

        @param flags: Feature bits. No bits are defined yet, must be 0
        @param sname: Short name (displayed on the button)
        @param lname: Long name (displayed in the menu)
        @param hint:  Hint for the input line

        @return Boolean: True-Success, False-Failed
        """

        # Already registered?
        if self.__cli_idx >= 0:
            return True

        if sname is not None: self.sname = sname
        if lname is not None: self.lname = lname
        if hint is not None:  self.hint  = hint

        # Register
        self.__cli_idx = _idaapi.install_command_interpreter(self)
        return False if self.__cli_idx < 0 else True


    def unregister(self):
        """
        Unregisters the CLI (if it was registered)
        """
        if self.__cli_idx < 0:
            return False

        _idaapi.remove_command_interpreter(self.__cli_idx)
        self.__cli_idx = -1
        return True


    def __del__(self):
        self.unregister()

    #
    # Implement these methods in the subclass:
    #
#<pydoc>
#    def OnExecuteLine(self, line):
#        """
#        The user pressed Enter. The CLI is free to execute the line immediately or ask for more lines.
#
#        This callback is mandatory.
#
#        @param line: typed line(s)
#        @return Boolean: True-executed line, False-ask for more lines
#        """
#        return True
#
#    def OnKeydown(self, line, x, sellen, vkey, shift):
#        """
#        A keyboard key has been pressed
#        This is a generic callback and the CLI is free to do whatever it wants.
#
#        This callback is optional.
#
#        @param line: current input line
#        @param x: current x coordinate of the cursor
#        @param sellen: current selection length (usually 0)
#        @param vkey: virtual key code. if the key has been handled, it should be returned as zero
#        @param shift: shift state
#
#        @return:
#            None - Nothing was changed
#            tuple(line, x, sellen, vkey): if either of the input line or the x coordinate or the selection length has been modified.
#            It is possible to return a tuple with None elements to preserve old values. Example: tuple(new_line, None, None, None) or tuple(new_line)
#        """
#        return None
#
#    def OnCompleteLine(self, prefix, n, line, prefix_start):
#        """
#        The user pressed Tab. Find a completion number N for prefix PREFIX
#
#        This callback is optional.
#
#        @param prefix: Line prefix at prefix_start (string)
#        @param n: completion number (int)
#        @param line: the current line (string)
#        @param prefix_start: the index where PREFIX starts in LINE (int)
#
#        @return: None if no completion could be generated otherwise a String with the completion suggestion
#        """
#        return None
#</pydoc>

#</pycode(py_cli)>
#<pycode(py_custviewer)>
class simplecustviewer_t(object):
    """The base class for implementing simple custom viewers"""
    def __init__(self):
        self.__this = None

    def __del__(self):
        """Destructor. It also frees the associated C++ object"""
        try:
            _idaapi.pyscv_delete(self.__this)
        except:
            pass

    @staticmethod
    def __make_sl_arg(line, fgcolor=None, bgcolor=None):
        return line if (fgcolor is None and bgcolor is None) else (line, fgcolor, bgcolor)

    def Create(self, title):
        """
        Creates the custom view. This should be the first method called after instantiation

        @param title: The title of the view
        @return: Boolean whether it succeeds or fails. It may fail if a window with the same title is already open.
                 In this case better close existing windows
        """
        self.title = title
        self.__this = _idaapi.pyscv_init(self, title)
        return True if self.__this else False

    def Close(self):
        """
        Destroys the view.
        One has to call Create() afterwards.
        Show() can be called and it will call Create() internally.
        @return: Boolean
        """
        return _idaapi.pyscv_close(self.__this)

    def Show(self):
        """
        Shows an already created view. It the view was close, then it will call Create() for you
        @return: Boolean
        """
        return _idaapi.pyscv_show(self.__this)

    def Refresh(self):
        return _idaapi.pyscv_refresh(self.__this)

    def RefreshCurrent(self):
        """Refreshes the current line only"""
        return _idaapi.pyscv_refresh_current(self.__this)

    def Count(self):
        """Returns the number of lines in the view"""
        return _idaapi.pyscv_count(self.__this)

    def GetSelection(self):
        """
        Returns the selected area or None
        @return:
            - tuple(x1, y1, x2, y2)
            - None if no selection
        """
        return _idaapi.pyscv_get_selection(self.__this)

    def ClearLines(self):
        """Clears all the lines"""
        _idaapi.pyscv_clear_lines(self.__this)

    def AddLine(self, line, fgcolor=None, bgcolor=None):
        """
        Adds a colored line to the view
        @return: Boolean
        """
        return _idaapi.pyscv_add_line(self.__this, self.__make_sl_arg(line, fgcolor, bgcolor))

    def InsertLine(self, lineno, line, fgcolor=None, bgcolor=None):
        """
        Inserts a line in the given position
        @return: Boolean
        """
        return _idaapi.pyscv_insert_line(self.__this, lineno, self.__make_sl_arg(line, fgcolor, bgcolor))

    def EditLine(self, lineno, line, fgcolor=None, bgcolor=None):
        """
        Edits an existing line.
        @return: Boolean
        """
        return _idaapi.pyscv_edit_line(self.__this, lineno, self.__make_sl_arg(line, fgcolor, bgcolor))

    def PatchLine(self, lineno, offs, value):
        """Patches an existing line character at the given offset. This is a low level function. You must know what you're doing"""
        return _idaapi.pyscv_patch_line(self.__this, lineno, offs, value)

    def DelLine(self, lineno):
        """
        Deletes an existing line
        @return: Boolean
        """
        return _idaapi.pyscv_del_line(self.__this, lineno)

    def GetLine(self, lineno):
        """
        Returns a line
        @param lineno: The line number
        @return:
            Returns a tuple (colored_line, fgcolor, bgcolor) or None
        """
        return _idaapi.pyscv_get_line(self.__this, lineno)

    def GetCurrentWord(self, mouse = 0):
        """
        Returns the current word
        @param mouse: Use mouse position or cursor position
        @return: None if failed or a String containing the current word at mouse or cursor
        """
        return _idaapi.pyscv_get_current_word(self.__this, mouse)

    def GetCurrentLine(self, mouse = 0, notags = 0):
        """
        Returns the current line.
        @param mouse: Current line at mouse pos
        @param notags: If True then tag_remove() will be called before returning the line
        @return: Returns the current line (colored or uncolored) or None on failure
        """
        return _idaapi.pyscv_get_current_line(self.__this, mouse, notags)

    def GetPos(self, mouse = 0):
        """
        Returns the current cursor or mouse position.
        @param mouse: return mouse position
        @return: Returns a tuple (lineno, x, y)
        """
        return _idaapi.pyscv_get_pos(self.__this, mouse)

    def GetLineNo(self, mouse = 0):
        """Calls GetPos() and returns the current line number or -1 on failure"""
        r = self.GetPos(mouse)
        return -1 if not r else r[0]

    def Jump(self, lineno, x=0, y=0):
        return _idaapi.pyscv_jumpto(self.__this, lineno, x, y)

    def AddPopupMenu(self, title, hotkey=""):
        """
        Adds a popup menu item
        @param title: The name of the menu item
        @param hotkey: Hotkey of the item or just empty
        @return: Returns the
        """
        return _idaapi.pyscv_add_popup_menu(self.__this, title, hotkey)

    def ClearPopupMenu(self):
        """
        Clears all previously installed popup menu items.
        Use this function if you're generating menu items on the fly (in the OnPopup() callback),
        and before adding new items
        """
        _idaapi.pyscv_clear_popup_menu(self.__this)

    def IsFocused(self):
        """Returns True if the current view is the focused view"""
        return _idaapi.pyscv_is_focused(self.__this)

    def GetTForm(self):
        """
        Return the TForm hosting this view.

        @return: The TForm that hosts this view, or None.
        """
        return _idaapi.pyscv_get_tform(self.__this)

    def GetTCustomControl(self):
        """
        Return the TCustomControl underlying this view.

        @return: The TCustomControl underlying this view, or None.
        """
        return _idaapi.pyscv_get_tcustom_control(self.__this)



    # Here are all the supported events
#<pydoc>
#    def OnClick(self, shift):
#        """
#        User clicked in the view
#        @param shift: Shift flag
#        @return: Boolean. True if you handled the event
#        """
#        print "OnClick, shift=%d" % shift
#        return True
#
#    def OnDblClick(self, shift):
#        """
#        User dbl-clicked in the view
#        @param shift: Shift flag
#        @return: Boolean. True if you handled the event
#        """
#        print "OnDblClick, shift=%d" % shift
#        return True
#
#    def OnCursorPosChanged(self):
#        """
#        Cursor position changed.
#        @return: Nothing
#        """
#        print "OnCurposChanged"
#
#    def OnClose(self):
#        """
#        The view is closing. Use this event to cleanup.
#        @return: Nothing
#        """
#        print "OnClose"
#
#    def OnKeydown(self, vkey, shift):
#        """
#        User pressed a key
#        @param vkey: Virtual key code
#        @param shift: Shift flag
#        @return: Boolean. True if you handled the event
#        """
#        print "OnKeydown, vk=%d shift=%d" % (vkey, shift)
#        return False
#
#    def OnPopup(self):
#        """
#        Context menu popup is about to be shown. Create items dynamically if you wish
#        @return: Boolean. True if you handled the event
#        """
#        print "OnPopup"
#
#    def OnHint(self, lineno):
#        """
#        Hint requested for the given line number.
#        @param lineno: The line number (zero based)
#        @return:
#            - tuple(number of important lines, hint string)
#            - None: if no hint available
#        """
#        return (1, "OnHint, line=%d" % lineno)
#
#    def OnPopupMenu(self, menu_id):
#        """
#        A context (or popup) menu item was executed.
#        @param menu_id: ID previously registered with add_popup_menu()
#        @return: Boolean
#        """
#        print "OnPopupMenu, menu_id=" % menu_id
#        return True
#</pydoc>
#</pycode(py_custviewer)>
%}
