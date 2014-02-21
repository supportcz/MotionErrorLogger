(********************************************************************
 * COPYRIGHT -- Bernecker + Rainer
 ********************************************************************
 * Program: MotionErrorLogger
 * File: MotionErrorLogger.st
 * Author: vancurar
 * Created: November 28, 2013
 ********************************************************************
 * Implementation of program MotionErrorLogger
 ********************************************************************)

PROGRAM _CYCLIC

	CASE step OF
		0:	(* check if there is a motion error *)
			MC_BR_AxisErrorCollector_0.Axis := mcALL_AXES;
			MC_BR_AxisErrorCollector_0.Enable := 1;
			
			IF MC_BR_AxisErrorCollector_0.FunctionBlockError OR MC_BR_AxisErrorCollector_0.AxisError OR 
				MC_BR_AxisErrorCollector_0.AxisWarning THEN
				step := step + 1;
			END_IF
		
		1:	(* wait till the errors are logged to NCT *)
			TON_0.IN := 1;
			TON_0.PT := T#3s;
		
			IF TON_0.Q THEN
				TON_0.IN := 0;
				step := step + 1;
			END_IF

		2:	(* determine data module name *)
			moduleIndex := moduleIndex + 1;
			IF moduleIndex > NB_MODULES THEN
				moduleIndex := 1;
			END_IF
			
			str1 := USINT_TO_STRING(moduleIndex);
			moduleName := CONCAT('mel',str1);
			step := step + 1;
		
		3:	(* save NCT to data module *)
			MC_BR_NetTrace_0.Execute := 1;
			MC_BR_NetTrace_0.Command := mcSAVE;
			MC_BR_NetTrace_0.Configuration.DatObj.Name := moduleName;
			MC_BR_NetTrace_0.Configuration.DatObj.Type := mcDATOBJ;
			MC_BR_NetTrace_0.Configuration.NetTrace.Type := mcNET_TRACE_GLOBAL;
			
			IF MC_BR_NetTrace_0.Done THEN
				MC_BR_NetTrace_0.Execute := 0;
				step := step + 1;
			END_IF
		
		4:	(* get handle to data module in DRAM *)
			DatObjInfo_0.enable := 1;
			DatObjInfo_0.pName := ADR(moduleName);
		
			IF DatObjInfo_0.status = 0 THEN
				doIdent := DatObjInfo_0.ident;
				DatObjInfo_0.enable := 0;
				step := step + 1;
			END_IF
		
		5:	(* move data module to UserROM *)
			DatObjMove_0.enable := 1;
			DatObjMove_0.ident := doIdent;
			DatObjMove_0.MemType := doUSRROM;
		
			IF DatObjMove_0.status = 0 THEN
				DatObjMove_0.enable := 0;
				step := step + 1;
			END_IF
		
		6:	(* wait till error disappears *)
			IF NOT (MC_BR_AxisErrorCollector_0.FunctionBlockError OR MC_BR_AxisErrorCollector_0.AxisError OR 
				MC_BR_AxisErrorCollector_0.AxisWarning) THEN
				step := step + 1;
			END_IF
			
		7:	(* go to the beginning *)
			step := 0;
	END_CASE;

	MC_BR_AxisErrorCollector_0();
	MC_BR_NetTrace_0();
	TON_0();
	DatObjInfo_0();
	DatObjMove_0();

	IF step = 0 THEN
		motionError := 0;
	ELSE
		motionError := 1;
	END_IF
	
END_PROGRAM