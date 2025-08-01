! REQUIRES: openmp_runtime

! This test checks the lowering of OpenMP sections construct with several clauses present

! RUN: %flang_fc1 -emit-hlfir %openmp_flags %s -o - | FileCheck %s
! RUN: bbc -hlfir -emit-hlfir %openmp_flags %s -o - | FileCheck %s

!CHECK: func @_QQmain() attributes {fir.bindc_name = "SAMPLE"} {
!CHECK:   %[[COUNT:.*]] = fir.address_of(@_QFEcount) : !fir.ref<i32>
!CHECK:   %[[COUNT_DECL:.*]]:2 = hlfir.declare %[[COUNT]] {uniq_name = "_QFEcount"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK:   %[[ETA:.*]] = fir.alloca f32 {bindc_name = "eta", uniq_name = "_QFEeta"}
!CHECK:   %[[CONST_1:.*]] = arith.constant 4 : i64
!CHECK:   %[[PRIVATE_ETA:.*]] = fir.alloca f32 {bindc_name = "eta", pinned, uniq_name = "_QFEeta"}
!CHECK:   %[[PRIVATE_ETA_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_ETA]] {uniq_name = "_QFEeta"} : (!fir.ref<f32>) -> (!fir.ref<f32>, !fir.ref<f32>)
!CHECK:   %[[PRIVATE_DOUBLE_COUNT:.*]] = fir.alloca i32 {bindc_name = "double_count", pinned, uniq_name = "_QFEdouble_count"} 
!CHECK:   %[[PRIVATE_DOUBLE_COUNT_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_DOUBLE_COUNT]] {uniq_name = "_QFEdouble_count"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK:   omp.sections allocate(%[[CONST_1]] : i64 -> %[[COUNT_DECL]]#0 : !fir.ref<i32>)  {
!CHECK:     omp.section {
!CHECK:       %[[CONST5:.*]] = arith.constant 5 : i32
!CHECK:       hlfir.assign %[[CONST5]] to %[[COUNT_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:       %[[TEMP_COUNT:.*]] = fir.load %[[COUNT_DECL]]#0 : !fir.ref<i32>
!CHECK:       %[[TEMP_DOUBLE_COUNT:.*]] = fir.load %[[PRIVATE_DOUBLE_COUNT_DECL]]#0 : !fir.ref<i32>
!CHECK:       %[[RESULT:.*]] = arith.muli %[[TEMP_COUNT]], %[[TEMP_DOUBLE_COUNT]] : i32
!CHECK:       %[[RESULT_CONVERT:.*]] = fir.convert %[[RESULT]] : (i32) -> f32
!CHECK:       hlfir.assign %[[RESULT_CONVERT]] to %[[PRIVATE_ETA_DECL]]#0 : f32, !fir.ref<f32>
!CHECK:       omp.terminator
!CHECK:     }
!CHECK:     omp.section {
!CHECK:       %[[TEMP:.*]] = fir.load %[[PRIVATE_DOUBLE_COUNT_DECL]]#0 : !fir.ref<i32>
!CHECK:       %[[CONST:.*]] = arith.constant 1 : i32
!CHECK:       %[[RESULT:.*]] = arith.addi %[[TEMP]], %[[CONST]] : i32
!CHECK:       hlfir.assign %[[RESULT]] to %[[PRIVATE_DOUBLE_COUNT_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:       omp.terminator
!CHECK:     }
!CHECK:     omp.section {
!CHECK:       %[[TEMP:.*]] = fir.load %[[PRIVATE_ETA_DECL]]#0 : !fir.ref<f32>
!CHECK:       %[[CONST:.*]] = arith.constant 7.000000e+00 : f32
!CHECK:       %[[RESULT:.*]] = arith.subf %[[TEMP]], %[[CONST]] {{.*}}: f32
!CHECK:       hlfir.assign %[[RESULT]] to %[[PRIVATE_ETA_DECL]]#0 : f32, !fir.ref<f32>
!CHECK:       %[[TEMP_COUNT1:.*]] = fir.load %[[COUNT_DECL]]#0 : !fir.ref<i32>
!CHECK:       %[[TEMP_COUNT:.*]] = fir.convert %[[TEMP_COUNT1]] : (i32) -> f32
!CHECK:       %[[TEMP_ETA:.*]] = fir.load %[[PRIVATE_ETA_DECL]]#0 : !fir.ref<f32>
!CHECK:       %[[TEMP_COUNT2:.*]] = arith.mulf %[[TEMP_COUNT]], %[[TEMP_ETA]] {{.*}}: f32
!CHECK:       %[[RESULT:.*]] = fir.convert %[[TEMP_COUNT2]] : (f32) -> i32
!CHECK:       hlfir.assign %[[RESULT]] to %[[COUNT_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:       %[[TEMP_COUNT3:.*]] = fir.load %[[COUNT_DECL]]#0 : !fir.ref<i32>
!CHECK:       %[[TEMP_COUNT4:.*]] = fir.convert %[[TEMP_COUNT3]] : (i32) -> f32
!CHECK:       %[[TEMP_ETA:.*]] = fir.load %[[PRIVATE_ETA_DECL]]#0 : !fir.ref<f32>
!CHECK:       %[[TEMP_COUNT5:.*]] = arith.subf %[[TEMP_COUNT4]], %[[TEMP_ETA]] {{.*}}: f32
!CHECK:       %[[RESULT2:.*]] = fir.convert %[[TEMP_COUNT5]] : (f32) -> i32
!CHECK:       hlfir.assign %[[RESULT2]] to %[[PRIVATE_DOUBLE_COUNT_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:       omp.terminator
!CHECK:     }
!CHECK:     omp.terminator
!CHECK:   }
!CHECK:   omp.sections nowait {
!CHECK:     omp.terminator
!CHECK:   }
!CHECK:   return
!CHECK: }

program sample
    use omp_lib
    integer :: count = 0, double_count = 1
    !$omp sections private (eta, double_count) allocate(omp_high_bw_mem_alloc: count)
        !$omp section
            count = 1 + 4
            eta = count * double_count
        !$omp section
            double_count = double_count + 1
        !$omp section
            eta = eta - 7
            count = count * eta
            double_count = count - eta
    !$omp end sections

    !$omp sections
    !$omp end sections nowait
end program sample

!CHECK: func @_QPfirstprivate(%[[ARG:.*]]: !fir.ref<f32> {fir.bindc_name = "alpha"}) {
!CHECK:   %[[ARG_DECL:.*]]:2 = hlfir.declare %[[ARG]] dummy_scope %{{[0-9]+}} {uniq_name = "_QFfirstprivateEalpha"} : (!fir.ref<f32>, !fir.dscope) -> (!fir.ref<f32>, !fir.ref<f32>) 
!CHECK:   %[[PRIVATE_ALPHA:.*]] = fir.alloca f32 {bindc_name = "alpha", pinned, uniq_name = "_QFfirstprivateEalpha"}
!CHECK:   %[[PRIVATE_ALPHA_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_ALPHA]] {uniq_name = "_QFfirstprivateEalpha"} : (!fir.ref<f32>) -> (!fir.ref<f32>, !fir.ref<f32>)
!CHECK:   %[[TEMP:.*]] = fir.load %[[ARG_DECL]]#0 : !fir.ref<f32>
!CHECK:   hlfir.assign %[[TEMP]] to %[[PRIVATE_ALPHA_DECL]]#0 : f32, !fir.ref<f32>
!CHECK:   omp.sections {
!CHECK:     omp.section  {
!CHECK:       omp.terminator
!CHECK:     }
!CHECK:     omp.terminator
!CHECK:   }
!CHECK:   omp.sections {
!CHECK:     omp.section  {
!CHECK:       %[[PRIVATE_VAR:.*]] = fir.load %[[ARG_DECL]]#0 : !fir.ref<f32>
!CHECK:       %[[CONSTANT:.*]] = arith.constant 5.000000e+00 : f32
!CHECK:       %[[PRIVATE_VAR_2:.*]] = arith.mulf %[[PRIVATE_VAR]], %[[CONSTANT]] {{.*}}: f32
!CHECK:       hlfir.assign %[[PRIVATE_VAR_2]] to %[[ARG_DECL]]#0 : f32, !fir.ref<f32>
!CHECK:       omp.terminator
!CHECK:     }
!CHECK:     omp.terminator
!CHECK:   }
!CHECK:   return
!CHECK: }

subroutine firstprivate(alpha)
    real :: alpha
    !$omp sections firstprivate(alpha)
    !$omp end sections

    !$omp sections
        alpha = alpha * 5
    !$omp end sections
end subroutine

!CHECK-LABEL: func @_QPlastprivate
subroutine lastprivate()
        integer :: x
!CHECK: %[[X:.*]] = fir.alloca i32 {bindc_name = "x", uniq_name = "_QFlastprivateEx"}
!CHECK: %[[X_DECL:.*]]:2 = hlfir.declare %[[X]] {uniq_name = "_QFlastprivateEx"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[PRIVATE_X:.*]] = fir.alloca i32 {bindc_name = "x", pinned, uniq_name = "_QFlastprivateEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFlastprivateEx"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: omp.sections   {
	!$omp sections lastprivate(x)
!CHECK: omp.section {
!CHECK: %[[CONST10:.*]] = arith.constant 10 : i32
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[RESULT:.*]] = arith.muli %[[CONST10]], %[[TEMP]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x * 10

!CHECK: omp.section {
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[CONST:.*]] = arith.constant 1 : i32
!CHECK: %[[RESULT:.*]] = arith.addi %[[TEMP]], %[[CONST]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: %[[TEMP1:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TEMP1]] to %[[X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x + 1
!CHECK: omp.terminator
!CHECK: }
    !$omp end sections

!CHECK: %[[PRIVATE_X:.*]] = fir.alloca i32 {bindc_name = "x", pinned, uniq_name = "_QFlastprivateEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFlastprivateEx"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[TEMP:.*]] = fir.load %[[X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TEMP]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.barrier
!CHECK: omp.sections {
    !$omp sections firstprivate(x) lastprivate(x)
!CHECK: omp.section {
!CHECK: %[[CONST:.*]] = arith.constant 10 : i32
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[RESULT:.*]] = arith.muli %[[CONST]], %[[TEMP]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x * 10
!CHECK: omp.section {
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[CONST:.*]] = arith.constant 1 : i32
!CHECK: %[[RESULT:.*]] = arith.addi %[[TEMP]], %[[CONST]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TEMP]] to %[[X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x + 1
!CHECK: omp.terminator
!CHECK: }
    !$omp end sections

!CHECK: %[[PRIVATE_X:.*]] = fir.alloca i32 {bindc_name = "x", pinned, uniq_name = "_QFlastprivateEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFlastprivateEx"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[TEMP:.*]] = fir.load %[[X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TEMP]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.barrier
!CHECK: omp.sections nowait {
    !$omp sections firstprivate(x) lastprivate(x)
!CHECK: omp.section {
!CHECK: %[[CONST:.*]] = arith.constant 10 : i32
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[RESULT:.*]] = arith.muli %[[CONST]], %[[TEMP]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x * 10
!CHECK: omp.section {
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[CONST:.*]] = arith.constant 1 : i32
!CHECK: %[[RESULT:.*]] = arith.addi %[[TEMP]], %[[CONST]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TEMP]] to %[[X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
        !$omp section
            x = x + 1
!CHECK: omp.terminator
!CHECK: }
!CHECK: omp.barrier
     !$omp end sections nowait

!CHECK: %[[PRIVATE_X:.*]] = fir.alloca i32 {bindc_name = "x", pinned, uniq_name = "_QFlastprivateEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFlastprivateEx"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: omp.sections {
!CHECK: omp.section {
!CHECK: cf.br ^bb1
!CHECK: ^bb1:  // pred: ^bb0
!CHECK: %[[INNER_PRIVATE_X:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: %[[CONST:.*]] = arith.constant 1 : i32
!CHECK: %[[RESULT:.*]] = arith.addi %[[INNER_PRIVATE_X]], %[[CONST]] : i32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: %[[LOADED_VALUE:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[LOADED_VALUE]] to %[[X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK: omp.terminator
!CHECK: }
!CHECK: omp.terminator
!CHECK: }
!CHECK: return
!CHECK: }
    !$omp sections lastprivate(x)
        !$omp section
                goto 30
        30  x = x + 1
    !$omp end sections
end subroutine

!CHECK-LABEL: func @_QPlastprivate2
!CHECK: %[[X:.*]] = fir.alloca i32 {bindc_name = "x", uniq_name = "_QFlastprivate2Ex"}
!CHECK: %[[X_DECL:.*]]:2 = hlfir.declare %[[X]] {uniq_name = "_QFlastprivate2Ex"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[Y:.*]] = fir.alloca i32 {bindc_name = "y", uniq_name = "_QFlastprivate2Ey"}
!CHECK: %[[Y_DECL:.*]]:2 = hlfir.declare %[[Y]] {uniq_name = "_QFlastprivate2Ey"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[PRIVATE_X:.*]] = fir.alloca i32 {bindc_name = "x", pinned, uniq_name = "_QFlastprivate2Ex"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFlastprivate2Ex"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[PRIVATE_Y:.*]] = fir.alloca i32 {bindc_name = "y", pinned, uniq_name = "_QFlastprivate2Ey"}
!CHECK: %[[PRIVATE_Y_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_Y]] {uniq_name = "_QFlastprivate2Ey"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: omp.sections {
!CHECK:   omp.section {
!CHECK:     %[[TEMP:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<i32>
!CHECK:     hlfir.assign %[[TEMP]] to %[[X_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:     %[[TEMP2:.*]] = fir.load %[[PRIVATE_Y_DECL]]#0 : !fir.ref<i32>
!CHECK:     hlfir.assign %[[TEMP2]] to %[[Y_DECL]]#0 : i32, !fir.ref<i32>
!CHECK:     omp.terminator
!CHECK:   }
!CHECK:   omp.terminator
!CHECK: }
subroutine lastprivate2()
    integer :: x, y

    !$omp sections lastprivate(x) lastprivate(y)
        !$omp section
          x = y + 1
    !$omp end sections
end subroutine

!CHECK-LABEL: func @_QPlastprivate_common
!CHECK: %[[I:.*]]:2 = hlfir.declare %{{.*}} {uniq_name = "_QFlastprivate_commonEi"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: %[[I_PRIV:.*]]:2 = hlfir.declare %{{.*}} {uniq_name = "_QFlastprivate_commonEi"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
!CHECK: omp.sections
!CHECK: omp.section
!CHECK: %[[TMP:.*]] = fir.load %[[I_PRIV]]#0 : !fir.ref<i32>
!CHECK: hlfir.assign %[[TMP]] to %[[I]]#0 : i32, !fir.ref<i32>
subroutine lastprivate_common()
    integer :: i
    common /com/ i

    i = 1
    !$omp sections lastprivate(/com/)
        i = 2
    !$omp end sections
end subroutine

!CHECK-LABEL: func @_QPunstructured_sections_privatization
subroutine unstructured_sections_privatization()
!CHECK: %[[X:.*]] = fir.alloca f32 {bindc_name = "x", uniq_name = "_QFunstructured_sections_privatizationEx"}
!CHECK: %[[X_DECL:.*]]:2 = hlfir.declare %[[X]] {uniq_name = "_QFunstructured_sections_privatizationEx"} : (!fir.ref<f32>) -> (!fir.ref<f32>, !fir.ref<f32>)
!CHECK: %[[PRIVATE_X:.*]] = fir.alloca f32 {bindc_name = "x", pinned, uniq_name = "_QFunstructured_sections_privatizationEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFunstructured_sections_privatizationEx"} : (!fir.ref<f32>) -> (!fir.ref<f32>, !fir.ref<f32>)
!CHECK: omp.sections {
!CHECK: omp.section {
!CHECK: cf.br ^bb1
!CHECK: ^bb1:  // pred: ^bb0
!CHECK: %[[INNER_PRIVATE_X:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<f32>
!CHECK: %[[CONSTANT:.*]] = arith.constant 1.000000e+00 : f32
!CHECK: %[[RESULT:.*]] = arith.addf %[[INNER_PRIVATE_X]], %[[CONSTANT]] fastmath<contract> : f32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : f32, !fir.ref<f32>
!CHECK: omp.terminator
!CHECK: }
!CHECK: omp.terminator
!CHECK: }
    !$omp sections private(x)
        !$omp section
            goto 40
        40  x = x + 1
    !$omp end sections
!CHECK: %[[PRIVATE_X:.*]] = fir.alloca f32 {bindc_name = "x", pinned, uniq_name = "_QFunstructured_sections_privatizationEx"}
!CHECK: %[[PRIVATE_X_DECL:.*]]:2 = hlfir.declare %[[PRIVATE_X]] {uniq_name = "_QFunstructured_sections_privatizationEx"} : (!fir.ref<f32>) -> (!fir.ref<f32>, !fir.ref<f32>)
!CHECK: %[[TEMP:.*]] = fir.load %[[X_DECL]]#0 : !fir.ref<f32>
!CHECK: hlfir.assign %[[TEMP]] to %[[PRIVATE_X_DECL]]#0 : f32, !fir.ref<f32>
!CHECK: omp.sections {
!CHECK: omp.section {
!CHECK: cf.br ^bb1
!CHECK: ^bb1:
!CHECK: %[[INNER_PRIVATE_X:.*]] = fir.load %[[PRIVATE_X_DECL]]#0 : !fir.ref<f32>
!CHECK: %[[CONSTANT:.*]] = arith.constant 1.000000e+00 : f32
!CHECK: %[[RESULT:.*]] = arith.addf %[[INNER_PRIVATE_X]], %[[CONSTANT]] fastmath<contract> : f32
!CHECK: hlfir.assign %[[RESULT]] to %[[PRIVATE_X_DECL]]#0 : f32, !fir.ref<f32>
!CHECK: omp.terminator
!CHECK: }
!CHECK: omp.terminator
!CHECK: }
    !$omp sections firstprivate(x)
        !$omp section
            goto 50
        50  x = x + 1
    !$omp end sections
end subroutine
