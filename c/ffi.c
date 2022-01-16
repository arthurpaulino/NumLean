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

const char* ERROR_INSUF_MEM = "insufficient memory";

typedef struct nl_matrix {
    uint32_t n_rows = 0;
    uint32_t n_cols = 0;
    uint32_t length = 0;
    double*    data = NULL;
} nl_matrix;

static lean_external_class* g_nl_matrix_external_class = NULL;

internal l_res make_error(const char* err_msg) {
    return lean_mk_io_user_error(lean_mk_io_user_error(lean_mk_string(err_msg)));
}

internal void nl_matrix_finalizer(void* m_) {
    nl_matrix* m = (nl_matrix*) m_;
    if (m->data) {
        free(m->data);
    }
    free(m);
}

internal void noop_foreach(void* mod, l_arg fn) {}

internal nl_matrix* nl_matrix_alloc(uint32_t n_rows, uint32_t n_cols) {
    nl_matrix* m = (nl_matrix*) malloc(sizeof(nl_matrix));
    if (!m) {
        return NULL;
    }
    m->data = (double*) malloc(n_rows * n_cols * sizeof(double)); // this product may overflow
    if (!m->data) {
        return NULL;
    }
    m->n_rows = n_rows;
    m->n_cols = n_cols;
    m->length = ((uint32_t) n_rows) * ((uint32_t) n_cols);
    return m;
}

internal nl_matrix* nl_matrix_copy(nl_matrix* m) {
    nl_matrix* m_ = nl_matrix_alloc(m->n_rows, m->n_cols);
    if (!m_) {
        return NULL;
    }
    memcpy(m_->data, m->data, m->length * sizeof(double)); // this product may overflow
    return m;
}

internal double get_val(nl_matrix* m, uint32_t i, uint32_t j) {
    return m->data[j + i * m->n_cols];
}

internal void set_val(nl_matrix* m, uint32_t i, uint32_t j, double v) {
    m->data[j + i * m->n_cols] = v;
}

internal l_obj* nl_matrix_box(nl_matrix* m) {
    return lean_alloc_external(g_nl_matrix_external_class, m);
}

internal nl_matrix* nl_matrix_unbox(l_obj* o) {
    return (nl_matrix*) lean_get_external_data(o);
}

// API

external l_res nl_initialize() {
    g_nl_matrix_external_class = lean_register_external_class(
        nl_matrix_finalizer,
        noop_foreach
    );
    return lean_io_result_mk_ok(lean_box(0));
}

external l_res nl_matrix_new(uint32_t n_rows, uint32_t n_cols, double v) {
    if (n_rows == 0) {
        return make_error("invalid number of columns");
    }
    if (n_cols == 0) {
        return make_error("invalid number of rows");
    }
    nl_matrix* m = nl_matrix_alloc(n_rows, n_cols);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    for (uint32_t i = 0; i < m->length; i++) {
        m->data[i] = v;
    }
    return lean_io_result_mk_ok(nl_matrix_box(m));
}

external l_res nl_matrix_id(uint32_t n) {
    if (n == 0) {
        return make_error("invalid dimension");
    }
    nl_matrix* m = nl_matrix_alloc(n, n);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    for (uint32_t i = 0; i < n; i++) {
        for (uint32_t j = 0; j < n; j++) {
            set_val(m, i, j, i == j ? 1.0 : 0.0);
        }
    }
    return lean_io_result_mk_ok(nl_matrix_box(m));
}

external l_res nl_matrix_from_values(uint32_t n_rows, uint32_t n_cols, l_arg float_array) {
    if (n_rows == 0) {
        return make_error("invalid number of columns");
    }
    if (n_cols == 0) {
        return make_error("invalid number of rows");
    }
    if (n_rows * n_cols != lean_sarray_size(float_array)) {
        return make_error("inconsistent shape and data size");
    }
    nl_matrix* m = nl_matrix_alloc(n_rows, n_cols);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    memcpy(m->data, lean_float_array_cptr(float_array), m->length * sizeof(double));
    return lean_io_result_mk_ok(nl_matrix_box(m));
}

external l_res nl_matrix_n_rows(l_arg _m) {
    return lean_io_result_mk_ok(lean_box_uint32(nl_matrix_unbox(_m)->n_rows));
}

external l_res nl_matrix_n_cols(l_arg _m) {
    return lean_io_result_mk_ok(lean_box_uint32(nl_matrix_unbox(_m)->n_cols));
}

external l_res nl_matrix_get_values(l_arg _m) {
    nl_matrix* m = nl_matrix_unbox(_m);
    l_res ret = lean_alloc_sarray(sizeof(double), m->length, m->length);
    memcpy(lean_float_array_cptr(ret), m->data, m->length * sizeof(double));
    return lean_io_result_mk_ok(ret);
}

external l_res nl_matrix_get_value(l_arg _m, uint32_t i, uint32_t j) {
    nl_matrix* m = nl_matrix_unbox(_m);
    if (i >= m->n_rows) {
        return make_error("invalid row index");
    }
    if (j >= m->n_cols) {
        return make_error("invalid column index");
    }
    return lean_io_result_mk_ok(lean_box_float(get_val(m, i, j)));
}

external l_res nl_matrix_transpose(l_arg _m) {
    nl_matrix* m = nl_matrix_unbox(_m);
    nl_matrix* m_ = nl_matrix_alloc(m->n_cols, m->n_rows);
    for (uint32_t i = 0; i < m->n_rows; i++) {
        for (uint32_t j = 0; j < m->n_cols; j++) {
            set_val(m_, j, i, get_val(m, i, j));
        }
    }
    return lean_io_result_mk_ok(nl_matrix_box(m_));
}

external l_res nl_matrix_plus_float(l_arg _m, double f) {
    nl_matrix* m = nl_matrix_copy(nl_matrix_unbox(_m));
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    if (f != 0.0) {
        for (uint32_t i = 0; i < m->length; i++) {
            m->data[i] = f + m->data[i];
        }
    }
    return lean_io_result_mk_ok(nl_matrix_box(m));
}

external l_res nl_matrix_times_float(l_arg _m, double f) {
    nl_matrix* m = nl_matrix_copy(nl_matrix_unbox(_m));
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    if (f != 0.0) {
        for (uint32_t i = 0; i < m->length; i++) {
            m->data[i] = f * m->data[i];
        }
    }
    return lean_io_result_mk_ok(nl_matrix_box(m));
}

external l_res nl_matrix_plus_nl_matrix(l_arg _m, l_arg __m) {
    nl_matrix* m = nl_matrix_unbox(_m);
    nl_matrix* m_ = nl_matrix_unbox(__m);
    if (m->n_rows != m_->n_rows || m->n_cols != m_->n_cols) {
        return make_error("inconsistent dimensions on sum");
    }
    nl_matrix* m__ = nl_matrix_alloc(m->n_rows, m->n_cols);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    for (uint32_t i = 0; i < m->length; i++) {
        m__->data[i] = m->data[i] + m_->data[i];
    }
    return lean_io_result_mk_ok(nl_matrix_box(m__));
}

external l_res nl_matrix_minus_nl_matrix(l_arg _m, l_arg __m) {
    nl_matrix* m = nl_matrix_unbox(_m);
    nl_matrix* m_ = nl_matrix_unbox(__m);
    if (m->n_rows != m_->n_rows || m->n_cols != m_->n_cols) {
        return make_error("inconsistent dimensions on subtraction");
    }
    nl_matrix* m__ = nl_matrix_alloc(m->n_rows, m->n_cols);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    for (uint32_t i = 0; i < m->length; i++) {
        m__->data[i] = m->data[i] - m_->data[i];
    }
    return lean_io_result_mk_ok(nl_matrix_box(m__));
}

external l_res nl_matrix_times_nl_matrix(l_arg _m, l_arg __m) {
    nl_matrix* m = nl_matrix_unbox(_m);
    nl_matrix* m_ = nl_matrix_unbox(__m);
    if (m->n_cols != m_->n_rows) {
        return make_error("inconsistent dimensions on product");
    }
    nl_matrix* m__ = nl_matrix_alloc(m->n_rows, m_->n_cols);
    if (!m) {
        return make_error(ERROR_INSUF_MEM);
    }
    // todo: use something smarter
    double sum = 0.0;
    for (uint32_t i = 0; i < m->n_rows; i++) {
        for (uint32_t j = 0; j < m_->n_cols; j++) {
            for (uint32_t k = 0; k < m->n_cols; k++) {
                sum = sum + get_val(m, i, k) * get_val(m_, k, j);
            }
            set_val(m__, i, j, sum);
            sum = 0.0;
        }
    }
    return lean_io_result_mk_ok(nl_matrix_box(m__));
}
