/*
SCRIPT DE CREACIÓN DE FUNCIONES ""TENTATIVAS"" DE LA BASE DE DATOS DEL BANCO
     - David García Guirado
     - Jorge García Marín
     - Agustín Prieto Páez
     - Jesús Sanz Alonso
     - Antonio Tendero Beltrán
*/


--=====================================
--				control
--=====================================
DROP FUNCTION control;
CREATE OR REPLACE FUNCTION control() RETURNS TABLE(su_id_ SUCURSAL.su_id%TYPE, cliente_ CUENTA.codigo%TYPE,tipo_cliente_ varchar(20),saldo_anterior CUENTA.saldo_actual%TYPE,saldo_nuevo_ CUENTA.saldo_actual%TYPE) AS $$ 
DECLARE
cursuc CURSOR FOR SELECT su_id FROM SUCURSAL;
curcli CURSOR(su_par SUCURSAL.su_id%TYPE) FOR SELECT codigo FROM CUENTA WHERE su_id=su_par;
saldo_ante CUENTA.saldo_actual%TYPE;
saldo_nuev CUENTA.saldo_actual%TYPE;
version varchar(20);
BEGIN
	FOR rec1 IN cursuc LOOP 
		FOR rec2 IN curcli(rec1.su_id) LOOP
			version:=checkSubtipo(rec2.codigo); 
			saldo_ante:=(SELECT rec2.saldo_actual);
			saldo_nuev:=actualizar_saldo(rec2,version);
			RETURN QUERY SELECT rec1.su_id,rec2.codigo,version,saldo_ante,saldo_nuev;
		END LOOP;
	END LOOP;
	RETURN;
END $$ LANGUAGE plpgsql;

--=====================================
--				checkSubtipo
--=====================================
DROP FUNCTION checkSubtipo;
CREATE OR REPLACE FUNCTION checkSubtipo(codc_arg CLIENTE.codigo%TYPE) RETURNS varchar AS $$
DECLARE 
mycod CLIENTE.codigo%TYPE;
fecha_act date:=(SELECT CURRENT_DATE);
fecha_nac date;
param varchar(20);
BEGIN 
	SELECT codigo INTO mycod FROM ORGANIZACION WHERE codigo=codc_arg;
	IF NOT FOUND THEN 
		SELECT codigo,fecha_nacimiento INTO STRICT mycod,fecha_nac FROM PERSONA WHERE codigo=codc_arg;
		IF fecha_act-fecha_nac>23742 --65 años en numero de dias(contando años bisiestos)--
		THEN param:='p_mayor';
		ELSE param:='p_menor';
		END IF; 

	ELSE SELECT tipo INTO param FROM ORGANIZACION WHERE codigo=mycod;
	END IF; 
RETURN param;
EXCEPTION 
	WHEN NO_DATA_FOUND THEN RAISE NOTICE 'El cliente no existe en la base de datos';
END 
$$ LANGUAGE plpgsql;

--=====================================
--				actualizar_saldo
--=====================================
-- Actualizar los saldos dependiendo del tipo (y subtipo) de Cliente
DROP FUNCTION actualizar_saldo;
CREATE OR REPLACE FUNCTION actualizar_saldo(mi_record RECORD, subtipo varchar(20), OUT saldo_ant CUENTA.saldo_actual%TYPE, OUT saldo_nuevo CUENTA.saldo_actual%TYPE) RETURNS RECORD AS 
$$
DECLARE 
	--mi_record RECORD;
BEGIN
	--FETCH curs INTO mi_record; 
	--RAISE NOTICE '%, %, %',mi_record.codigo,mi_record.saldo_actual;
	SELECT saldo_actual INTO saldo_ant FROM CUENTA WHERE codigo = mi_record.codigo;
	RAISE NOTICE '%',saldo_ant;
	RAISE NOTICE '%',
		CASE subtipo 
			WHEN 'p_menor' THEN 
				'Persona Menor de 65 años'
			WHEN 'p_mayor' THEN 
				'Persona Mayor de 65 años'
			WHEN 'PYME' THEN 
				'Organización PYME'
			WHEN 'Gran empresa' THEN 
				'Organización Gran Empresa'
		END
	;
	
	SELECT 
		CASE subtipo 
			WHEN 'p_menor' THEN 
				1.08 --bono del 8% para las personas de 65 años o menos
			WHEN 'p_mayor' THEN 
				1.1 --bono del 10% para las personas de más de 65 años
			WHEN 'PYME' THEN 
				1.15 --bono del 15% para las pymes
			WHEN 'Gran empresa' THEN 
				1.2 --bono del 20% para las grandes empresas
		END
	*saldo_ant INTO saldo_nuevo;
END
$$ LANGUAGE PLPGSQL;
