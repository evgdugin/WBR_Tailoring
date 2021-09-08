﻿CREATE PROCEDURE [Products].[TechnologicalSequence_SetBySketch]
	@sketch_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @data_tab TABLE (
	        	operation_range SMALLINT,
	        	ct_id INT,
	        	ta_id INT,
	        	element_id INT,
	        	equipment_id INT,
	        	dr_id TINYINT,
	        	dc_id TINYINT,
	        	operation_value DECIMAL(9, 3),
	        	discharge_id TINYINT,
	        	rotaiting DECIMAL(9, 5),
	        	dc_coefficient DECIMAL(9, 5),
	        	comment VARCHAR(100),
	        	comment_id INT
	        )
	
	INSERT INTO @data_tab
		(
			operation_range,
			ct_id,
			ta_id,
			element_id,
			equipment_id,
			dr_id,
			dc_id,
			operation_value,
			discharge_id,
			rotaiting,
			dc_coefficient,
			comment
		)
	SELECT	ml.value('@range', 'smallint'),
			ml.value('@ct', 'int'),
			ml.value('@ta', 'int'),
			ml.value('@el', 'int'),
			ml.value('@eq', 'int'),
			ml.value('@dr', 'tinyint'),
			ml.value('@dc', 'tinyint'),
			ml.value('@val', 'DECIMAL(9, 3)'),
			ml.value('@de', 'tinyint'),
			ml.value('@rot', 'DECIMAL(9, 5)'),
			ml.value('@dcc', 'DECIMAL(9, 5)'),
			ml.value('@com', 'VARCHAR(100)')
	FROM	@data_xml.nodes('technology/opern')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN oa.cnt_operation_range > 1 THEN 'Операция с порядковым номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' встречается более одного раза.'
	      	                   WHEN dt.operation_range IS NULL THEN 'Присутствует не пронумерованная строка.'
	      	                   WHEN ct.ct_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код типа ткани ' + CAST(dt.ct_id AS VARCHAR(10))
	      	                   WHEN ta.ta_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код действия ' + CAST(dt.ta_id AS VARCHAR(10))
	      	                   WHEN e.element_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код элемента ' + CAST(dt.element_id AS VARCHAR(10))
	      	                   WHEN eq.equipment_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код оборудования ' + CAST(dt.equipment_id AS VARCHAR(10))
	      	                   WHEN dr.dr_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код сложности ткани ' + CAST(dt.dr_id AS VARCHAR(10))
	      	                   WHEN dc.dc_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код сложности рисунка ' + CAST(dt.dc_id AS VARCHAR(10))
	      	                   WHEN d.discharge_id IS NULL THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' указан не сущестующий код разряда ' + CAST(dt.discharge_id AS VARCHAR(10))
	      	                   WHEN ISNULL(dt.operation_value, 0) = 0 THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' не заполнен размер операции'
	      	                   WHEN ISNULL(dt.rotaiting, 0) = 0 THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' не заполнена норма по операции'
	      	                   WHEN ISNULL(dt.dc_coefficient, 0) = 0 THEN 'В строке с номером ' + CAST(dt.operation_range AS VARCHAR(10)) +
	      	                        ' не заполнен коэффициент сложности рисунка'
	      	                   WHEN oa2.cnt_double_operation > 1 THEN 'Операция с порядковым номером ' + CAST(oa2.min_or AS VARCHAR(10)) + 
	      	                        ' задублирована с операцией ' +
	      	                        CAST(oa2.max_or AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = dt.ct_id   
			LEFT JOIN	Technology.TechAction ta
				ON	ta.ta_id = dt.ta_id   
			LEFT JOIN	Technology.Element e
				ON	e.element_id = dt.element_id   
			LEFT JOIN	Technology.Equipment eq
				ON	eq.equipment_id = dt.equipment_id   
			LEFT JOIN	Technology.DifficultyRebuffing dr
				ON	dr.dr_id = dt.dr_id   
			LEFT JOIN	Technology.DrawingComplexity dc
				ON	dc.dc_id = dt.dc_id   
			LEFT JOIN	Technology.Discharge d
				ON	d.discharge_id = dt.discharge_id   
			OUTER APPLY (
			      	SELECT	COUNT(dt2.operation_range) cnt_operation_range
			      	FROM	@data_tab dt2
			      	WHERE	dt2.operation_range = dt.operation_range
			      ) oa
			OUTER APPLY (
	      			SELECT	COUNT(dt2.operation_range) cnt_double_operation,
	      					MAX(dt2.operation_range) max_or,
	      					MIN(dt2.operation_range) min_or
	      			FROM	@data_tab dt2
	      			WHERE	dt2.ta_id = dt.ta_id
	      					AND	dt2.element_id = dt.element_id
	      					AND	dt2.equipment_id = dt.equipment_id
	      					AND	ISNULL(dt2.comment, '') =
	      			   			ISNULL(dt.comment, '')
				  ) oa2
	WHERE	oa.cnt_operation_range > 1
			OR	dt.operation_range IS NULL
			OR	ct.ct_id IS NULL
			OR	ta.ta_id IS NULL
			OR	e.element_id IS NULL
			OR	eq.equipment_id IS NULL
			OR	dr.dr_id IS NULL
			OR	d.discharge_id IS NULL
			OR	ISNULL(dt.operation_value, 0) = 0
			OR	ISNULL(dt.rotaiting, 0) = 0
			OR	ISNULL(dt.dc_coefficient, 0) = 0
			OR	oa2.cnt_double_operation > 1
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO Technology.CommentDict
	(
		comment
	)
	SELECT	DISTINCT dt.comment
	FROM	@data_tab dt
	WHERE	dt.comment IS NOT NULL
			AND	NOT EXISTS (
			   		SELECT	1
			   		FROM	Technology.CommentDict cd
			   		WHERE	cd.comment = dt.comment
			   	)
	
	UPDATE	dt
	SET 	comment_id = cd.comment_id
	FROM	@data_tab dt
			INNER JOIN	Technology.CommentDict cd
				ON	cd.comment = ISNULL(dt.comment, '')
	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Products.SketchTechnologyJob
			(
				sketch_id,
				create_dt,
				create_employee_id,
				begin_dt,
				begin_employee_id,
				qp_id
			)
		SELECT	@sketch_id,
				@dt,
				@employee_id,
				@dt,
				@employee_id,
				2
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.SketchTechnologyJob stj
		     		WHERE	stj.sketch_id = @sketch_id
		     	)
		
		;
		WITH cte_Target AS(
			SELECT	ts.ts_is,
					ts.sketch_id,
					ts.operation_range,
					ts.ct_id,
					ts.ta_id,
					ts.element_id,
					ts.equipment_id,
					ts.dr_id,
					ts.dc_id,
					ts.operation_value,
					ts.discharge_id,
					ts.rotaiting,
					ts.dc_coefficient,
					ts.employee_id,
					ts.dt,
					ts.operation_time, 
					ts.comment_id					
			FROM	Products.TechnologicalSequence ts
			WHERE	ts.sketch_id = @sketch_id
		)
		MERGE cte_Target t
		USING @data_tab s
				ON s.operation_range = t.operation_range
		WHEN MATCHED AND (
		     	s.ct_id != t.ct_id
		     	OR s.ta_id != t.ta_id
		     	OR s.element_id != t.element_id
		     	OR s.equipment_id != t.equipment_id
		     	OR s.dr_id != t.dr_id
		     	OR s.dc_id != t.dc_id
		     	OR s.operation_value != t.operation_value
		     	OR s.discharge_id != t.discharge_id
		     	OR s.rotaiting != t.rotaiting
		     	OR s.dc_coefficient != t.dc_coefficient
		     	OR s.comment_id != t.comment_id
		     ) THEN 
		     UPDATE	
		     SET 	ct_id               = s.ct_id,
		     		ta_id               = s.ta_id,
		     		element_id          = s.element_id,
		     		equipment_id        = s.equipment_id,
		     		dr_id               = s.dr_id,
		     		dc_id               = s.dc_id,
		     		operation_value     = s.operation_value,
		     		discharge_id        = s.discharge_id,
		     		rotaiting           = s.rotaiting,
		     		dc_coefficient      = s.dc_coefficient,
		     		employee_id         = @employee_id,
		     		dt                  = @dt,
		     		comment_id			= s.comment_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		operation_range,
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dr_id,
		     		dc_id,
		     		operation_value,
		     		discharge_id,
		     		rotaiting,
		     		dc_coefficient,
		     		employee_id,
		     		dt,
		     		comment_id
		     	)
		     VALUES
		     	(
		     		@sketch_id,
		     		s.operation_range,
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dr_id,
		     		s.dc_id,
		     		s.operation_value,
		     		s.discharge_id,
		     		s.rotaiting,
		     		s.dc_coefficient,
		     		@employee_id,
		     		@dt,
		     		s.comment_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	OUTPUT	ISNULL(INSERTED.ts_is, DELETED.ts_is),
		           			ISNULL(INSERTED.sketch_id, DELETED.sketch_id),
		           			ISNULL(INSERTED.operation_range, DELETED.operation_range),
		           			ISNULL(INSERTED.ct_id, DELETED.ct_id),
		           			ISNULL(INSERTED.ta_id, DELETED.ta_id),
		           			ISNULL(INSERTED.element_id, DELETED.element_id),
		           			ISNULL(INSERTED.equipment_id, DELETED.equipment_id),
		           			ISNULL(INSERTED.dr_id, DELETED.dr_id),
		           			ISNULL(INSERTED.dc_id, DELETED.dc_id),
		           			ISNULL(INSERTED.operation_value, DELETED.operation_value),
		           			ISNULL(INSERTED.discharge_id, DELETED.discharge_id),
		           			ISNULL(INSERTED.rotaiting, DELETED.rotaiting),
		           			ISNULL(INSERTED.dc_coefficient, DELETED.dc_coefficient),
		           			ISNULL(INSERTED.employee_id, DELETED.employee_id),
		           			ISNULL(INSERTED.dt, DELETED.dt),
		           			ISNULL(INSERTED.operation_time, DELETED.operation_time),
		           			LEFT($action, 1),
		           			ISNULL(INSERTED.comment_id, DELETED.comment_id)
		           	INTO	History.TechnologicalSequence (
		           			ts_is,
		           			sketch_id,
		           			operation_range,
		           			ct_id,
		           			ta_id,
		           			element_id,
		           			equipment_id,
		           			dr_id,
		           			dc_id,
		           			operation_value,
		           			discharge_id,
		           			rotaiting,
		           			dc_coefficient,
		           			employee_id,
		           			dt,
		           			operation_time,
		           			operation,
		           			comment_id
		           		);
		
		MERGE Technology.TechActionRationing t
		USING (
		      	SELECT	dt.ct_id,
		      			dt.ta_id,
		      			dt.element_id,
		      			dt.equipment_id,
		      			dt.dr_id,
		      			MAX(dt.rotaiting) rotaiting
		      	FROM	@data_tab dt
		      	GROUP BY
		      		dt.ct_id,
		      		dt.ta_id,
		      		dt.element_id,
		      		dt.equipment_id,
		      		dt.dr_id
		      ) s
				ON t.ct_id = s.ct_id
				AND t.ta_id = s.ta_id
				AND t.element_id = s.element_id
				AND t.equipment_id = s.equipment_id
				AND t.dr_id = s.dr_id
		WHEN MATCHED AND t.rotaiting != s.rotaiting THEN 
		     UPDATE	
		     SET 	rotaiting = s.rotaiting
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dr_id,
		     		rotaiting
		     	)
		     VALUES
		     	(
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dr_id,
		     		s.rotaiting
		     	) 
		     OUTPUT	ISNULL(INSERTED.ct_id, DELETED.ct_id),
		     		ISNULL(INSERTED.ta_id, DELETED.ta_id),
		     		ISNULL(INSERTED.element_id, DELETED.element_id),
		     		ISNULL(INSERTED.equipment_id, DELETED.equipment_id),
		     		ISNULL(INSERTED.dr_id, DELETED.dr_id),
		     		ISNULL(INSERTED.rotaiting, DELETED.rotaiting),
		     		@dt,
		     		@employee_id,
		     		UPPER(LEFT($action, 1))
		     INTO	History.TechActionRationing (
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dr_id,
		     		rotaiting,
		     		dt,
		     		employee_id,
		     		operation
		     	);
		
		MERGE Technology.TechActionDCCoefficient t
		USING (
		      	SELECT	dt.ct_id,
		      			dt.ta_id,
		      			dt.element_id,
		      			dt.equipment_id,
		      			dt.dc_id,
		      			MAX(dt.dc_coefficient) dc_coefficient
		      	FROM	@data_tab dt
		      	GROUP BY
		      		dt.ct_id,
		      		dt.ta_id,
		      		dt.element_id,
		      		dt.equipment_id,
		      		dt.dc_id
		      ) s
				ON t.ct_id = s.ct_id
				AND t.ta_id = s.ta_id
				AND t.element_id = s.element_id
				AND t.equipment_id = s.equipment_id
				AND t.dc_id = s.dc_id
		WHEN MATCHED AND t.dc_coefficient != s.dc_coefficient THEN 
		     UPDATE	
		     SET 	dc_coefficient = s.dc_coefficient
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dc_id,
		     		dc_coefficient
		     	)
		     VALUES
		     	(
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dc_id,
		     		s.dc_coefficient
		     	)
		     OUTPUT	ISNULL(INSERTED.ct_id, DELETED.ct_id),
		     		ISNULL(INSERTED.ta_id, DELETED.ta_id),
		     		ISNULL(INSERTED.element_id, DELETED.element_id),
		     		ISNULL(INSERTED.equipment_id, DELETED.equipment_id),
		     		ISNULL(INSERTED.dc_id, DELETED.dc_id),
		     		ISNULL(INSERTED.dc_coefficient, DELETED.dc_coefficient),
		     		@dt,
		     		@employee_id,
		     		UPPER(LEFT($action, 1))
		     INTO	History.TechActionDCCoefficient (
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dc_id,
		     		dc_coefficient,
		     		dt,
		     		employee_id,
		     		operation
		     	);
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 