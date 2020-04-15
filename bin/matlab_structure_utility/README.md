matlab_structure_utility
========================

Utility functions for structures in Matlab. Contains functions to concatenate (cat), merge and override structures.

(1) cat_struct:
Syntax:
   C = cat_struct(dim, A, B)
   C = cat_struct(dim, A1, A2, A3, A4, ...)
Description:
  Allows for concatenation of array structures with different fieldnames by introducing the missing fieldnames and setting their values empty. Internally calls the function cat after missing fieldnames have been supplied with empty value fields.

(2) merge_struct:
Syntax:
  A = merge_struct(A, B)
  A = merge_struct(A1, A2, A3, A4, ...)
Description:
  Merges scalar structures into a single structure containing all fieldnames of the supplied structures. The last instance of any fieldname will set the final value of this fieldname.

(3) override_struct:
Syntax:
  A = override_struct(A, B)
  A = override_struct(A, B1, B2, B3, B4, ...)
  A = override_struct(A, Name, Value, ...)
Description:
  Overrides fieldnames in the structure A with the values of the same fieldname in structure B. Fieldnames in B that do not exists in A are ignored. Fieldnames to be overridden can also be supplied as Name/Value pairs, which makes this function a lightweight alternative to the excellent inputParser object for simple input parsing without any explicit error control.
