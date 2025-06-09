---
created_at: 2024-03-29 10:59:23 +0100
author: Piotr Jurewicz
tags: [ 'ruby' ]
publish: false
---

# How does Ruby resolve constants? Module nesting explained

A fundamental aspect of Ruby that often puzzles newcomers (and sometimes even seasoned developers) is how it resolves
constants, especially within nested modules and classes.

```C
    /* in current lexical scope */
	const rb_cref_t *root_cref = rb_vm_get_cref(th->cfp->ep);
	const rb_cref_t *cref;
	VALUE klass = Qnil;

	while (root_cref && CREF_PUSHED_BY_EVAL(root_cref)) {
	    root_cref = CREF_NEXT(root_cref);
	}
	cref = root_cref;
	while (cref && CREF_NEXT(cref)) {
	    if (CREF_PUSHED_BY_EVAL(cref)) {
		klass = Qnil;
	    }
	    else {
		klass = CREF_CLASS(cref);
	    }
	    cref = CREF_NEXT(cref);

	    if (!NIL_P(klass)) {
		VALUE av, am = 0;
		rb_const_entry_t *ce;
	      search_continue:
		if ((ce = rb_const_lookup(klass, id))) {
		    rb_const_warn_if_deprecated(ce, klass, id);
		    val = ce->value;
		    if (val == Qundef) {
			if (am == klass) break;
			am = klass;
			if (is_defined) return 1;
			if (rb_autoloading_value(klass, id, &av)) return av;
			rb_autoload_load(klass, id);
			goto search_continue;
		    }
		    else {
			if (is_defined) {
			    return 1;
			}
			else {
			    return val;
			}
		    }
		}
	    }
	}

	/* search self */
	if (root_cref && !NIL_P(CREF_CLASS(root_cref))) {
	    klass = vm_get_iclass(th->cfp, CREF_CLASS(root_cref));
	}
	else {
	    klass = CLASS_OF(th->cfp->self);
	}

	if (is_defined) {
	    return rb_const_defined(klass, id);
	}
	else {
	    return rb_const_get(klass, id);
	}
```


