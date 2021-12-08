/*
    Copyright (c) 2021 Arthur Paulino. All rights reserved.
    Released under Apache 2.0 license as described in the file LICENSE.
    Authors: Arthur Paulino
*/

#include <lean/lean.h>
#include <cstring>
#include <stdio.h>

#define internal inline static
#define external extern "C" LEAN_EXPORT
#define l_arg b_lean_obj_arg
#define l_res lean_obj_res
#define l_obj lean_object

typedef struct nl_array {
    uint64_t length = 0;
    double*    data = NULL;
} nl_array;

static lean_external_class* g_nl_array_external_class = NULL;

internal void nl_array_finalizer(void* arr_) {
    nl_array* arr = (nl_array*) arr_;
    if (arr->data) {
        free(arr->data);
    }
    free(arr);
}

internal void noop_foreach(void* mod, l_arg fn) {}

internal l_res make_error(const char* err_msg) {
    return lean_mk_io_user_error(lean_mk_io_user_error(lean_mk_string(err_msg)));
}

internal lean_object* nl_array_box(nl_array* arr) {
    return lean_alloc_external(g_nl_array_external_class, arr);
}

internal nl_array* nl_array_unbox(l_obj* o) {
    return (nl_array*) lean_get_external_data(o);
}

internal double get_val(nl_array* arr, uint64_t i) {
    return *(arr->data + i * sizeof(double));
}

internal void set_val(nl_array* arr, uint64_t i, double v) {
    *(arr->data + i * sizeof(double)) = v;
}

// API

external l_res nl_initialize() {
    g_nl_array_external_class = lean_register_external_class(
        nl_array_finalizer,
        noop_foreach
    );
    return lean_io_result_mk_ok(lean_box(0));
}

external l_res nl_array_mk(uint64_t length) {
    nl_array* arr = (nl_array*) malloc(sizeof(nl_array));
    if (!arr) {
        return make_error("no memory");
    }
    arr->data = (double*) malloc(length * sizeof(double));
    if (!arr->data) {
        return make_error("no memory");
    }
    for (uint64_t i = 0; i < length; i++) {
        set_val(arr, i, 0.0);
    }
    arr->length = length;
    return lean_io_result_mk_ok(nl_array_box(arr));
}

// external double nl_array_get_i(l_arg arr_, uint64_t i) {
//     nl_array* arr = (nl_array*) nl_array_unbox(arr_);
//     // if (i >= arr->length || i < 0) {
//     //     return make_error("invalid index");
//     // }
//     return get_val(arr, i);
// }

// external l_res nl_array_to_lean_array(l_arg arr_) {
//     nl_array* arr = (nl_array*) nl_array_unbox(arr_);
//     l_res ret = lean_alloc_sarray(sizeof(double), arr->length, arr->length);
//     double* destination = lean_float_array_cptr(ret);
//     memcpy(destination, arr->data, arr->length * sizeof(double));
//     return ret;
// }

external l_res nl_array_plus_float(l_arg arr_, double f) {
    nl_array* arr = (nl_array*) nl_array_unbox(arr_);
    for (uint64_t i = 0; i < arr->length; i++) {
        set_val(arr, i, f + get_val(arr, i));
    }
    return lean_io_result_mk_ok(lean_box(0));
}

external l_res nl_array_times_float(l_arg arr_, double f) {
    nl_array* arr = (nl_array*) nl_array_unbox(arr_);
    for (uint64_t i = 0; i < arr->length; i++) {
        set_val(arr, i, f * get_val(arr, i));
    }
    return lean_io_result_mk_ok(lean_box(0));
}
