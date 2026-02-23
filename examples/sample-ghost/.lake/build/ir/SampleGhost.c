// Lean compiler output
// Module: SampleGhost
// Imports: public import Init public import UkaLean public import SampleGhost.Handlers
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
lean_object* lp_uka_x2dlean_UkaLean_registraShiori(lean_object*);
LEAN_EXPORT lean_object* lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2____boxed(lean_object*);
extern lean_object* lp_sample_x2dghost_SampleGhost_tractatores;
LEAN_EXPORT lean_object* lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2_();
LEAN_EXPORT lean_object* lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2_() {
_start:
{
lean_object* x_2; lean_object* x_3; 
x_2 = lp_sample_x2dghost_SampleGhost_tractatores;
x_3 = lp_uka_x2dlean_UkaLean_registraShiori(x_2);
return x_3;
}
}
LEAN_EXPORT lean_object* lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2____boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2_();
return x_2;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_uka_x2dlean_UkaLean(uint8_t builtin);
lean_object* initialize_sample_x2dghost_SampleGhost_Handlers(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_sample_x2dghost_SampleGhost(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_uka_x2dlean_UkaLean(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_sample_x2dghost_SampleGhost_Handlers(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = lp_sample_x2dghost_initFn_00___x40_SampleGhost_4129439195____hygCtx___hyg_2_();
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
