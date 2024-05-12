/*
SCRIPT DE CREACIÓN DE FUNCIONES ""TENTATIVAS"" DE LA BASE DE DATOS DEL BANCO
     - David García Guirado
     - Jorge García Marín
     - Agustín Prieto Páez
     - Jesús Sanz Alonso
     - Antonio Tendero Beltrán
*/

CREATE OR REPLACE FUNCTION control() RETURNS SETOF TEXT AS $$ 
DECLARE
cursuc CURSOR FOR SELECT su_id FROM SUCURSAL;
curcli CURSOR(su_par SUCURSAL.su_id%TYPE) FOR SELECT codc FROM CUENTA WHERE su_id=su_par;
orgx boolean;
version varchar(20);
recf1 record;
fila text;
BEGIN
	FOR rec1 IN cursus LOOP 
		FOR rec2 IN curcli(rec1.su_id) LOOP
			version:=checkSubtipo(rec2.codc); 
			recf1:=actualizar_saldo(rec2,version); --Devuelva el saldo anterior y el saldo actualizado y usa la iteracion del cursor para actualizar la cuenta dependiendo de version 
			fila:='Sucursal:'||rec1.su_id||', cliente:' || rec2.codc ||', saldo anterior:'|| recf1.saldo_ant ||', saldo nuevo:'||recf1.saldo_nuevo; 
			RETURN NEXT fila;
		END LOOP;
	END LOOP;
RETURN;
END $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION checksubtipo(codc_arg CLIENTE.codc%TYPE, OUT param varchar(20)) AS $$
DECLARE 
mycod CLIENTE.codc%TYPE;
fecha_act date:=(SELECT CURRENT_DATE)
fecha_nac date;
BEGIN 
	SELECT codc INTO mycod FROM ORGANIZACION WHERE codc=codc_arg;
	IF NOT FOUND THEN 
		SELECT codc,fecha_nacimiento INTO STRICT mycod,fecha_nac FROM PERSONA WHERE codc=codc_arg;
		IF fecha_act-fecha_nac>23742 --65 años en numero de dias(contando años bisiestos)--
		THEN param:='p_mayor';
		ELSE param:='p_menor';
		END IF; 

	ELSE SELECT tipo INTO param FROM ORGANIZACION WHERE codc=mycod;
	END IF; 

EXCEPTION 
	WHEN NO_DATA_FOUND THEN RAISE NOTICE 'El cliente no existe en la base de datos';
END 
$$ LANGUAGE plpgsql;


-- Actualizar los saldos dependiendo del tipo (y subtipo) de Cliente
CREATE OR REPLACE FUNCTION actualizar_saldo(curs refcursor, subtipo varchar(20), OUT saldo_ant CUENTA.saldo_actual%TYPE, OUT saldo_nuevo CUENTA.saldo_actual%TYPE)
RETURNS RECORD AS $$
DECLARE 
	mi_record RECORD;
BEGIN
FETCH curs INTO mi_record;
SELECT saldo_actual INTO saldo_ant FROM CUENTA WHERE codigo = mi_record.codigo; 
    CASE subtipo
        WHEN 'persona menor' THEN
            RAISE NOTICE 'Persona Menor de 65 años'; 
			SELECT 1.08*saldo_ant INTO saldo_nuevo;
        WHEN 'persona mayor' THEN
            RAISE NOTICE 'Persona Mayor de 65 años';
			SELECT 1.1*saldo_ant INTO saldo_nuevo;
        WHEN 'PYME' THEN
            RAISE NOTICE 'Organización PYME';
			SELECT 1.15*saldo_ant INTO saldo_nuevo;
        WHEN 'Gran empresa' THEN
            RAISE NOTICE 'Organización Gran Empresa';
			SELECT 1.2*saldo_ant INTO saldo_nuevo;
END
$$ LANGUAGE plpgsql;






