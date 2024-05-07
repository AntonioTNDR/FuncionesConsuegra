/*
SCRIPT DE CREACIÓN DE FUNCIONES ""TENTATIVAS"" DE LA BASE DE DATOS DEL BANCO
     - David García Guirado
     - Jorge García Marín
     - Agustín Prieto Páez
     - Jesús Sanz Alonso
     - Antonio Tendero Beltrán
*/

/*
Doble bucle que gestiona el tipo de cliente y su actualizacion llamando a las otras 2 funciones, para cada sucursal,
para cada uno de sus clientes se actualiza su saldo dependiendo de su subtipo, al final devuelve un informe en forma de setof text de todas las actualizaciones
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
			version:=isorg(rec2.codc); 
			recf1:=actualizar(curcli,version); --Devuelva el saldo anterior y el saldo actualizado y usa la iteracion del cursor para actualizar la cuenta dependiendo de version 
			fila:='Sucursal:'||rec1.su_id||', cliente:' || rec2.codc ||', saldo anterior:'|| recf1.saldo_ant ||', saldo nuevo:'||recf1.saldo_nuevo; 
			RETURN NEXT fila;
		END LOOP;
	END LOOP;
RETURN;
END $$ LANGUAGE plpgsql;


--Obtiene el subtipo del cliente, si es una organizacion obtenemos su tipo y si es una persona los dividimos en grupos (mayor y menor) segun su edad actual--
CREATE OR REPLACE FUNCTION checksubtipo(codc CLIENTE.codc%TYPE, OUT param varchar(20)) RETURNS record AS $$
DECLARE 
mycod CLIENTE.codc%TYPE;
org boolean NOT NULL:=1;
fecha_act date:=(SELECT CURRENT_DATE)
fecha_nac date;
BEGIN 
	SELECT codc INTO mycod FROM ORGANIZACION WHERE codc=mycod;
	IF NOT FOUND THEN 
		SELECT codc,fecha_nacimiento INTO STRICT mycod,fecha_nac FROM PERSONA WHERE codc=mycod;
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


-- Actualizar los saldos dependiendo del tipo (y subtipo) de Cliente--
CREATE OR REPLACE FUNCTION actualizar_saldo(curs refcursor, subtipo varchar(20))
RETURNS VOID AS $$
BEGIN
    CASE subtipo
        WHEN 'p_menor' THEN
            RAISE NOTICE 'Persona Menor de 65 años';
        WHEN 'p_mayor' THEN
            RAISE NOTICE 'Persona Mayor de 65 años';
        WHEN 'o_pyme' THEN
            RAISE NOTICE 'Organización PYME';
        WHEN 'o_gran' THEN
            RAISE NOTICE 'Organización Gran Empresa';
END
$$ LANGUAGE plpgsql;







