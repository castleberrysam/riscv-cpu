/*
 ****************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *
 *  Version:    C, Version 2.1
 *
 *  File:       dhry_1.c (part 2 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 ****************************************************************************
 */

#include "dhry.h"

Rec_Type        Rec_1, Rec_2;
Rec_Pointer     Ptr_Glob,
                Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
                Ch_2_Glob;
int             Arr_1_Glob [50];
int             Arr_2_Glob [50] [50];

int main (void)
{
  One_Fifty       Int_1_Loc;
  One_Fifty       Int_2_Loc;
  One_Fifty       Int_3_Loc;
  char            Ch_Index;
  Enumeration     Enum_Loc;
  Str_30          Str_1_Loc;
  Str_30          Str_2_Loc;
  int             Run_Index;
  int             Number_Of_Runs;

  Next_Ptr_Glob = &Rec_1;
  Ptr_Glob = &Rec_2;

  Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
  Ptr_Glob->Discr                       = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp      = 40;
  strcpy (Ptr_Glob->variant.var_1.Str_Comp,
          "DHRYSTONE PROGRAM, SOME STRING");
  strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");
  Arr_2_Glob [8][7] = 10;
  Number_Of_Runs = 1000;

  for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index)
  {

    Proc_5();
    Proc_4();
    Int_1_Loc = 2;
    Int_2_Loc = 3;
    strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
    Enum_Loc = Ident_2;
    Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);

    while (Int_1_Loc < Int_2_Loc)
    {
      Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
      Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
      Int_1_Loc += 1;
    }

    Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
    Proc_1 (Ptr_Glob);

    for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
    {
      if (Enum_Loc == Func_1 (Ch_Index, 'C'))
      {
        Proc_6 (Ident_1, &Enum_Loc);
        strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
        Int_2_Loc = Run_Index;
        Int_Glob = Run_Index;
      }
    }

    Int_2_Loc = Int_2_Loc * Int_1_Loc;
    Int_1_Loc = Int_2_Loc / Int_3_Loc;
    Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;

    Proc_2 (&Int_1_Loc);
  }
}

void Proc_1 (Rec_Pointer Ptr_Val_Par)
{
  Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;

  *Ptr_Val_Par->Ptr_Comp = *Ptr_Glob;

  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (&Next_Record->Ptr_Comp);

  if (Next_Record->Discr == Ident_1)
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp,
           &Next_Record->variant.var_1.Enum_Comp);

    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7 (Next_Record->variant.var_1.Int_Comp, 10,
           &Next_Record->variant.var_1.Int_Comp);
  }
  else
    *Ptr_Val_Par = *Ptr_Val_Par->Ptr_Comp;
}

void Proc_2 (One_Fifty *Int_Par_Ref)
{
  One_Fifty  Int_Loc;
  Enumeration   Enum_Loc;

  Int_Loc = *Int_Par_Ref + 10;
  do
    if (Ch_1_Glob == 'A')
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    }
  while (Enum_Loc != Ident_1);
}

void Proc_3 (Rec_Pointer *Ptr_Ref_Par)
{
  if (Ptr_Glob != Null)
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
}

void Proc_4 (void)
{
  Boolean Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
}

void Proc_5 (void)
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
}
