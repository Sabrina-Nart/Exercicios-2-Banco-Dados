
EXERCÍCIO 1

VERIFICAR A MÉDIA DE SALÁRIO DOS FUNCIONARIOS POR PROJETO, SENDO 
QUE PARA OS FUNCIONARIOS QUE:
- TRABALHAM EM UM PROJETO NA MESMA CIDADE ONDE RESIDEM,  CONCEDER 
 UM AUMENTO SALARIAL REFERENTE A 10% DA MÉDIA 
  SALARIAL DO PROJETO;
- TRABALHAM EM UM PROJETO EM UMA CIDADE DIFERENTE DA QUE RESIDEM,
  CONCEDER UM AUMENTO SALARIAL REFERENTE A 
  PERCENTUAL DE DIFERENÇA ENTRE O SEU SALÁRIO E A MÉDIA SALARIAL DO PROJETO. 
  OBS.: NÃO PRECISAM SE PREOCUPAR EM RESOLVER OS CASOS ONDE O FUNCIONÁRIO 
  TRABALHA EM MAIS QUE UM PROJETO QUE SE ENCAIXA NAS DUAS SITUAÇÕES.

DO $$
DECLARE
	CUR_PROJETOS CURSOR FOR SELECT FUNCIONARIOS_PROJETOS.I_PROJETO, 
								   FUNCIONARIOS_PROJETOS.I_FUNCIONARIO, 
								   FUNCIONARIOS.SALARIO,
								   FUNCIONARIOS.I_CIDADE,
								   PROJETOS.I_CIDADE
							 FROM FUNCIONARIOS INNER JOIN FUNCIONARIOS_PROJETOS 
								  ON(FUNCIONARIOS.I_FUNCIONARIO = 
									 FUNCIONARIOS_PROJETOS.I_FUNCIONARIO)
								  INNER JOIN PROJETOS
								  ON(FUNCIONARIOS_PROJETOS.I_PROJETO = PROJETOS.I_PROJETO);
			  
    V_PROJETO INTEGER;
    V_FUNCIONARIO INTEGER;
    V_SALARIO DECIMAL(12,2);
    V_CID_FUNC INTEGER;
    V_CID_PROJ INTEGER;
    V_MEDIA_SAL DECIMAL(12,2);
    V_DIFERENCA DECIMAL(12,2);
	
BEGIN
	
	OPEN CUR_PROJETOS;
	
	LOOP
		FETCH CUR_PROJETOS INTO V_PROJETO, V_FUNCIONARIO, V_SALARIO,
		                        V_CID_FUNC, V_CID_PROJ;
		EXIT WHEN NOT FOUND; 
		
		SELECT AVG(SALARIO) INTO V_MEDIA_SAL 
		  FROM FUNCIONARIOS_PROJETOS INNER JOIN FUNCIONARIOS
		       ON(FUNCIONARIOS_PROJETOS.I_FUNCIONARIO = 
		       	  FUNCIONARIOS.I_FUNCIONARIO)
		 WHERE FUNCIONARIOS_PROJETOS.I_PROJETO = V_PROJETO;
		 
		IF V_CID_PROJ = V_CID_FUNC THEN
			UPDATE FUNCIONARIOS 
			   SET SALARIO = SALARIO + ( V_MEDIA_SAL * 0.10)
			 WHERE FUNCIONARIOS.I_FUNCIONARIO = V_FUNCIONARIO;
		ELSE
			V_DIFERENCA := (((V_SALARIO * 100)/V_MEDIA_SAL) - 100);
			IF V_DIFERENCA = 0 THEN
			   V_DIFERENCA := 1;
			ELSIF V_DIFERENCA < 0 THEN
			   V_DIFERENCA := ROUND(((V_DIFERENCA * (-1))/100),2) + 1;
			END IF;
			UPDATE FUNCIONARIOS 
			   SET SALARIO = SALARIO * V_DIFERENCA
			 WHERE FUNCIONARIOS.I_FUNCIONARIO = V_FUNCIONARIO;
		END IF;
		
	END LOOP;
	
	CLOSE CUR_PROJETOS;
	
END $$;
	
/////////////////////////////////////////////////////
		
EXERCÍCIO 2		

O ALUNO DEVE:
CRIAR UMA COLUNA NA TABELA DE FUNCIONARIOS QUE DEVERÁ SE CHAMAR: SALARIO_HORA

DEPOIS VOCÊS DEVEM CRIAR UM SCRIPT SQL DE PROGRAMAÇÃO ESTRUTURADA PARA PERCORRER 
OS FUNCIONARIOS VERIFICANDO O TOTAL DE HORAS QUE ELES TRABALHAM(SOMA DAS HORAS 
DOS DIFERENTES PROJETOS QUE CADA UM PARTICIPA) E CALCULAR O VALOR POR HORA DO 
FUNCIONARIO, E ENTÃO ALIMENTAR A COLUNA CRIADA COM O VALOR DA HORA DO FUNCIONARIO.
OBS.: COMO O SALÁRIO É MENSAL E AS HORAS POR PROJETO SÃO SEMANAIS, 
CONSIDERAR QUE "UM MÊS CHEIO" POSSUI 4 SEMANAS.

ALTER TABLE FUNCIONARIOS
ADD COLUMN SALARIO_HORA NUMERIC(12,2);

COMMIT;

DO $$
 DECLARE
 	C_FUNC CURSOR FOR SELECT funcionarios.i_funcionario, 
						   SUM(funcionarios_projetos.horas_semana),
						   funcionarios.salario 
					  FROM funcionarios INNER JOIN funcionarios_projetos
						   ON funcionarios_projetos.i_funcionario = funcionarios.i_funcionario
					 GROUP BY funcionarios.i_funcionario;
	 
 	v_funcionario INTEGER;
 	v_hrsem DECIMAL(12,2);
	v_salario DECIMAL(12,2);
	
BEGIN
	OPEN C_FUNC;
	
	LOOP
		FETCH C_FUNC INTO v_funcionario, v_hrsem,v_salario;
		EXIT WHEN NOT FOUND;
		UPDATE funcionarios 
		   SET salario_hora = v_salario / (v_hrsem * 4) 
		WHERE i_funcionario = v_funcionario;
	END LOOP;
	
	CLOSE C_FUNC;
	
END $$;

COMMIT;

/////////////////////////////////////////////////////

EXERCÍCIO 3

CRIAR UM BLOCO DE PROGRAMAÇÃO ESTRUTURADA QUE IDENTIFIQUE QUAL O FUNCIONARIO COM O MAIOR VALOR DE SALARIO POR HORA
E O FUNCIONARIO COM MENOR VALOR DE SALÁRIO POR HORA, E AUMENTE O VALOR DA HORA E SALARIO DE TODOS(MENOS DO
FUNCIONARIO DE MAIOR VALOR HORA) EM METADE DO VALOR DA DIFERENÇA, ENTRE O VALOR DA HORA MAIS CARA E MAIS BARATA. 
O SALARIO DOS FUNCIONARIO DEVERÃO SER AUMENTADOS/RECALCULADOS DE ACORDO COM O NOVO VALOR DA HORA.
EXEMPLO: 
MENOR_VALOR_HORA = R$ 50,00
MAIOR_VALOR_HORA = R$ 100,00
DIFERENCA = 100 - 50 = R$ 50,00
METADE_DO_VALOR_DA_DIFERENCA = 50 / 2 = R$ 25,00

do $$
 declare	
 	C_FUNC CURSOR FOR SELECT i_funcionario,salario_hora FROM funcionarios;
 	v_id_f INTEGER;
 	v_salario_hora DECIMAL(12,2);
	v_maior_salario DECIMAL(12,2);
	v_diferenca DECIMAL(12,2);
begin
	SELECT MAX(salario_hora) INTO v_maior_salario  FROM funcionarios;
	SELECT MAX(salario_hora) - MIN(salario_hora)  INTO v_diferenca  FROM funcionarios;
	
	UPDATE funcionarios set salario_hora = salario_hora + (v_diferenca/2) 
		WHERE salario_hora <> v_maior_salario;
	OPEN C_FUNC;
	
	LOOP
		FETCH C_FUNC INTO v_id_f,v_salario_hora;
		EXIT WHEN NOT FOUND;
		
		IF v_salario_hora <> v_maior_salario THEN
			UPDATE funcionarios set salario = salario_hora * ((SELECT SUM(horas_semana) 
				                                                 FROM funcionarios_projetos WHERE i_funcionario = v_id_f)*4) 
			WHERE i_funcionario = v_id_f;
		END IF;
	END LOOP;
	
	CLOSE C_FUNC;
	
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 4

Criar um bloco de programação estruturada para apresentar no console 
do browser do banco de dados: o nome dos clientes e o valor final das
 compras que estão abaixo do valor médio.
 
DO $$
DECLARE

	C_1 CURSOR FOR SELECT  b.nome, a.i_venda, a.valor_final FROM vendas AS a
					INNER JOIN clientes AS b ON b.i_cliente = a.i_cliente;
	v_NOME VARCHAR(50);
	V_VALOR_FINAL DECIMAL(12,2);
	V_MEDIA DECIMAL(12,2);
	V_COD_VENDA INTEGER;
	
BEGIN

	OPEN C_1;
	
	LOOP
		FETCH C_1 INTO V_NOME, V_COD_VENDA, V_VALOR_FINAL;
		
		EXIT WHEN NOT FOUND;
		
		SELECT AVG(valor_final) INTO V_MEDIA
		FROM vendas;
		
		IF V_VALOR_FINAL < V_MEDIA THEN
			RAISE NOTICE 'CLIENTE % - % - %',V_COD_VENDA, V_NOME,V_VALOR_FINAL;
		END IF;
		
	END LOOP;
	
	CLOSE C_1;
	
END $$;

-------------------------------

DO $$
DECLARE 
	lista cursor for select cl.nome, v.valor_final from vendas v
	inner join clientes cl on(cl.i_cliente = v.i_cliente);
	
	nomeCliente varchar(100);
	valorFinal decimal (12,2);
	media decimal(12,2);
	
begin
	open lista;
		select avg(valor_final) into media from vendas;
		
	loop
		fetch lista into nomeCliente,valorFinal;
		exit when not found;
		
		if valorFinal < media then
			raise notice 'Cliente: % - Valor Final: %', nomeCliente, valorFinal;
		end if;	
		
	end loop;

	close lista;

end $$

------------------------------------

DO $$
DECLARE 
	C_CLI CURSOR FOR SELECT c.i_cliente, c.nome, vendas.valor_final FROM CLIENTES AS C
						INNER JOIN  
						vendas  on (c.i_cliente = vendas.i_cliente);
		
	v_cliente integer;
	v_nome VARCHAR(45);
	v_valor_final DECIMAL(12,2);	
	v_valor_medio DECIMAL(12,2);
	
BEGIN
	SELECT AVG(valor_final) INTO v_valor_medio FROM vendas;
	
	OPEN C_CLI;

	LOOP

	FETCH C_CLI INTO v_cliente, v_nome, v_valor_final;

	EXIT WHEN NOT FOUND;
		
		IF v_valor_final < v_valor_medio then
			RAISE NOTICE 'Nome: %, Valor final: %', v_nome, v_valor_final;
		END IF;
		
	END LOOP;

	CLOSE C_CLI;

END $$

------------------------------------

do $$
 declare	
 	C_CLIENTE CURSOR FOR 
	
	select clientes.nome,vendas.valor_final,(select round(((SUM(vendas.valor_final))/count(vendas.valor_final)),2) from vendas) soma 
	  from clientes
		inner join vendas
			ON clientes.i_cliente = vendas.i_cliente
			group by clientes.nome,
			vendas.valor_final;
			
 	V_CLIENTE VARCHAR;
	V_VALOR_FINAL DECIMAL(12,2);
	V_VALOR_MEDIO DECIMAL(12,2);
	vcont INTEGER := 0;
	
begin
	OPEN C_CLIENTE;
	loop
		FETCH C_CLIENTE INTO V_CLIENTE, V_VALOR_FINAL, V_VALOR_MEDIO;
		
		EXIT WHEN NOT FOUND;
		vcont := vcont + 1;
		
		IF V_VALOR_FINAL < V_VALOR_MEDIO THEN
			RAISE NOTICE 'Cliente % Valor compra %',V_CLIENTE,V_VALOR_FINAL;	
		
		END IF;
		
	END LOOP;
	
	CLOSE C_CLIENTE;
	
	RAISE NOTICE 'Número de linhas processadas na tabela de projetos: %', vcont;
	
END $$;

------------------------------------

DO $$
	DECLARE
	C_1 CURSOR FOR SELECT  b.nome,a.valor_final 
	                 FROM vendas AS a INNER JOIN clientes AS b 
	                      ON b.i_cliente = a.i_cliente
	                WHERE a.valor_final < (SELECT AVG(vendas.valor_final) FROM vendas);
	v_NOME VARCHAR(50);
	V_VALOR_FINAL DECIMAL(12,2);
	
BEGIN
	
	OPEN C_1;
	
	LOOP
		FETCH C_1 INTO V_NOME, V_VALOR_FINAL;
		EXIT WHEN NOT FOUND;
		RAISE NOTICE 'CLIENTE % - %',V_NOME,V_VALOR_FINAL;
		
	END LOOP;
	
	CLOSE C_1;
	
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 5

Criar um bloco de programação estruturada para aumentar o preço de 
cada produto em 5%, sendo que as vendas realizadas no mês de setembro 
também deverão sofrer este reajuste, o que implica na modificação dos
campos de valores nas tabelas de itens e vendas. 
Obs.: NÃO é necessário modificar a tabela de contas a receber.

DO $$
	DECLARE
	BEGIN
		UPDATE produtos SET valor = valor + (valor * 0.05);
		UPDATE itens_vendas SET valor_venda = valor_venda + (valor_venda * 0.05) 
		 WHERE i_item IN ( SELECT a.i_item FROM itens_vendas AS a
			                     INNER JOIN vendas AS b ON b.i_venda = a.i_venda
			                 WHERE EXTRACT(MONTH FROM b.data_venda)  = 09);
		UPDATE vendas 
		   SET valor_venda = valor_venda + (valor_venda * 0.05),
		   	   desconto = (valor_venda + (valor_venda * 0.05)) - valor_final
		 WHERE EXTRACT(MONTH FROM data_venda)  = 09;
END $$;

------------------------------------

DO $$
DECLARE

BEGIN
	UPDATE produtos SET valor = valor + (valor * 0.05);
	UPDATE itens_vendas SET valor_venda = valor_venda + (valor_venda * 0.05) 
	 WHERE itens_vendas.i_venda IN ( SELECT b.i_venda 
	 	                               FROM vendas AS b 
		                               WHERE EXTRACT(MONTH FROM b.data_venda)  = 09);
	UPDATE vendas 
	   SET valor_venda = valor_venda + (valor_venda * 0.05),
	   	   desconto = (valor_venda + (valor_venda * 0.05)) - valor_final
	 WHERE EXTRACT(MONTH FROM data_venda)  = 09;
		 
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 6

Construa um script SQL, utilizando programação estruturada.
O script deverá inserir o um novo produto, exceto pelo nome e código. 
O novo nome do produto deverá ser definido por você, 
já o código deverá ser igual ao maior código existente na tabela de 
produtos mais 1.

DO $$
DECLARE
	v_id_max integer;
	
BEGIN
	SELECT MAX(i_produto)+ 1 INTO v_id_max FROM produtos;
	INSERT INTO produtos VALUES (v_id_max,'Produto 1',10.15);
		
END $$;

------------------------------------

DO $$
	BEGIN
		INSERT INTO produtos
		SELECT i_produto + 1, 'NOVO NOME DE PRODUTO', valor 
		  FROM produtos
		 WHERE i_produto = (SELECT MAX(i_produto) from produtos);
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 7

Criar um script SQL para procurar na tabela de vendas, todas as 
vendas cujo valor não confere com a soma do valor dos itens da venda.
 Para as vendas que se encontrarem na situação descrita, alterar o 
 valor da venda para o valor total dos itens da venda.

DO $$
DECLARE
	C_4 CURSOR FOR SELECT  i_venda,valor_venda FROM vendas;
	V_I_VENDA INTEGER;
	V_VALOR_VENDA DECIMAL(12,2);
	V_VALOR_ITENS DECIMAL(12,2);
	
BEGIN
	OPEN C_4;
	
	LOOP
		FETCH C_4 INTO V_I_VENDA, V_VALOR_VENDA;
		EXIT WHEN NOT FOUND;
		SELECT SUM(valor_venda*quantidade) INTO V_VALOR_ITENS
		FROM itens_vendas WHERE i_venda = V_I_VENDA;
		
		IF V_VALOR_ITENS <> V_VALOR_VENDA THEN
			UPDATE vendas 
			   SET valor_venda = V_VALOR_ITENS,
			       desconto = V_VALOR_ITENS - VALOR_FINAL
			 WHERE i_venda = V_I_VENDA;
		END IF;
	
	END LOOP;
	
	CLOSE C_4;
	
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 8

Criar um campo do tipo numeric(12,2) na tabela de CLIENTES, para armazenar o valor de crédito pré-aprovado 
que ela possui para compras. Após a criação desse campo na tabela de pessoa, deve-se criar um bloco de 
programação não identificada para alimentar esse campo para cada pessoa. O valor desse campo deverá ser 
o valor médio das vendas já realizadas para as respectivas pessoas. Para pessoas que nunca tiveram vendas 
registradas, o limite de crédito pré-aprovado será 0(ZERO).

DO $$
DECLARE 
	lista cursor for select cl.i_cliente, avg(v.valor_final) from clientes cl
	inner join vendas v on(cl.i_cliente = v.i_cliente) group by cl.i_cliente;
	
	id_cliente integer;
	valor_credito decimal (12,2);
	
begin
	open lista;
	
	loop
		fetch lista into id_cliente, valor_credito;
		exit when not found;
		
		if  valor_credito > 0 then
			update clientes cl set credito = valor_credito where cl.i_cliente = id_cliente;
		else
			update clientes cl set credito = 0 where cl.i_cliente = id_cliente;
		end if;	
		
		end loop;
		
	close lista;
end $$

/////////////////////////////////////////////////////
	
EXERCÍCIO 9

DO $$
DECLARE
	C_1 CURSOR FOR SELECT  a.i_cliente,COUNT(b.i_venda) FROM clientes AS a
	LEFT JOIN vendas AS b ON b.i_cliente = a.i_cliente
	GROUP BY 1;
	
	cliente INTEGER;
	qtde INTEGER;
	
BEGIN
	OPEN C_1;
	
		LOOP
			FETCH C_1 INTO cliente,qtde;
			EXIT WHEN NOT FOUND;
			IF qtde > 0 THEN
				UPDATE clientes SET creditos = (SELECT AVG(valor_venda) FROM vendas WHERE i_cliente = cliente) WHERE i_cliente = cliente;
			ELSE
				UPDATE clientes SET creditos = 0 WHERE i_cliente = cliente;
			END IF;
		END LOOP;
		
	CLOSE C_1;
	
END $$;

/////////////////////////////////////////////////////

EXERCÍCIO 10

Blocos de programação SQL não identificados, são blocos de comando que somente pode ser executados diretamente 
no banco de dados, não permitindo seu armazenamento e chamada a partir de outros blocos SQL. Dessa forma, 
pede-se a criação de um bloco de programação SQL que aumente em 7,5% o valor de todos os produtos que já 
tiveram pelo menos uma venda, ou seja, tem um registro na tabela de itens_vendas. A alteração deve ser 
aplicada a todos os produtos, porém deve ser alterado um produto por vez, dessa forma, seu código deve estar 
preparado para isso.

DO $$
DECLARE 
	lista cursor for select p.valor, p.i_produto from produtos p
	inner join itens_vendas v on(v.i_produto = p.i_produto); -- group by cl.i_cliente;
	
	valor_aumento numeric(12,2);
	id_produto integer;
	
begin
	open lista;

	loop
		fetch lista into valor_aumento, id_produto;
		exit when not found;
		
		update produtos p set valor = (valor_aumento + 0.75) where p.i_produto = id_produto;	
	end loop;
	
	close lista;
	
end $$

------------------------------------

DO $$
DECLARE
	C_2 CURSOR FOR SELECT  i_produto FROM produtos WHERE  EXISTS (SELECT i_produto FROM itens_vendas);
	produto INTEGER;
	
BEGIN
	OPEN C_2;
	
	LOOP
		FETCH C_2 INTO produto;
		EXIT WHEN NOT FOUND;
		UPDATE produtos SET valor = valor + (valor * 0.075) WHERE i_produto = produto;
	END LOOP;
	
	CLOSE C_2;
	
END $$;	