/*
SCRIPT DE CREACIÓN DE FUNCIONES ""TENTATIVAS"" DE LA BASE DE DATOS DEL BANCO
     - David García Guirado
     - Jorge García Marín
     - Agustín Prieto Páez
     - Jesús Sanz Alonso
     - Antonio Tendero Beltrán
*/

-- Actualizar los saldos dependiendo del tipo (y subtipo) de Cliente
CREATE OR REPLACE FUNCTION actualizar_saldo(curs REFCURSOR, subtipo varchar(10))
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
