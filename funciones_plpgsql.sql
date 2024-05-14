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
--				FUNCIONA, NO TOCAR
--=====================================
CREATE OR REPLACE FUNCTION control() RETURNS TABLE(sucursal SUCURSAL.su_id%TYPE, cliente CUENTA.codigo%TYPE, tipo_cliente varchar(20), saldo_anterior CUENTA.saldo_actual%TYPE, saldo_nuevo CUENTA.saldo_actual%TYPE) AS $$ 
DECLARE
	curs_suc CURSOR FOR SELECT su_id FROM SUCURSAL;
	curs_cli CURSOR(su_par SUCURSAL.su_id%TYPE) FOR SELECT * FROM CUENTA WHERE su_id = su_par;
	saldo_old CUENTA.saldo_actual%TYPE;
	saldo_new CUENTA.saldo_actual%TYPE;
	subtipo varchar(20);
BEGIN
	FOR rec1 IN curs_suc LOOP
		FOR rec2 IN curs_cli(rec1.su_id) LOOP
			subtipo := checkSubtipo(rec2.codigo);
			saldo_old := (SELECT rec2.saldo_actual);
			saldo_new := actualizar_saldo(curs_cli, subtipo);
			RETURN QUERY SELECT rec1.su_id, rec2.codigo, subtipo, saldo_old, saldo_new;
		END LOOP;
	END LOOP;
	RETURN;
END $$ LANGUAGE plpgsql;

--=====================================
--				checkSubtipo
--				NO TOCAR, FUNCIONA
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
--				FUNCIONA, NO TOCAR
--=====================================
-- Actualizar el saldo dependiendo del tipo (y subtipo) del cliente en cuestión
CREATE OR REPLACE FUNCTION actualizar_saldo(curs REFCURSOR, subtipo varchar(20), saldo_new OUT CUENTA.saldo_actual%type) AS $$
BEGIN
    CASE subtipo
        WHEN 'p_menor' THEN
            RAISE NOTICE 'Persona Menor de 65 años';
            UPDATE CUENTA SET saldo_actual = saldo_actual*0.9
            WHERE CURRENT OF curs
            RETURNING saldo_actual INTO saldo_new;  -- Actualizar el saldo del cliente (-10%)
        WHEN 'p_mayor' THEN
            RAISE NOTICE 'Persona Mayor de 65 años';
            UPDATE CUENTA SET saldo_actual = saldo_actual*1.25
            WHERE CURRENT OF curs
            RETURNING saldo_actual INTO saldo_new;  -- Actualizar el saldo del cliente (+25%)
        WHEN 'PYME' THEN
            RAISE NOTICE 'Organización PYME';
            UPDATE CUENTA SET saldo_actual = saldo_actual*0.85
            WHERE CURRENT OF curs
            RETURNING saldo_actual INTO saldo_new;  -- Actualizar el saldo del cliente (-15%)
        WHEN 'Gran empresa' THEN
            RAISE NOTICE 'Organización Gran Empresa';
            UPDATE CUENTA SET saldo_actual = saldo_actual*0.95
            WHERE CURRENT OF curs
            RETURNING saldo_actual INTO saldo_new;  -- Actualizar el saldo del cliente (-5%)
    END CASE;
END
$$ LANGUAGE plpgsql;
