create database Hotel;
use Hotel;

create table Pessoa(
id varchar(10) not null primary key(id),
nome varchar(50) not null,
sexo char(1) check(sexo in ('M', 'F')),
morada varchar(100) not null,
codPostal varchar(8) not null,
localidade varchar(20) not null,
telefone varchar(9) not null unique(telefone),
email varchar(100) not null unique(email), 
dataNasc date not null);

create table Hospede(
id varchar(10) not null references Pessoa(id),
codHospede int not null identity(1,1) primary key(codHospede),
descontos decimal default 20);

create table Hotel(
id int not null references Hospede(codHospede),
classificacao decimal(2,1) not null);

create table Departamento(nome varchar(20) not null primary key(nome));

create table Funcionarios(
id varchar(10) not null references Pessoa(id),
codFun int not null identity(1,1) primary key(codFun),
depart varchar(20) not null references Departamento(nome),
cargo varchar(20) not null,
dataAdmissao date not null,
salario money not null);

create table TipoApartamento(
tipoApart varchar(20) not null primary key(tipoApart));

create table Apartamento(
codApart int not null identity(1,1) primary key(codApart),
localizacao char(2) not null unique(localizacao),
disponivel bit not null,
tipoApart varchar(20) not null references TipoApartamento(tipoApart),
quantQuartos smallint not null,
precoDia money not null,
limpo bit not null);

create table Reserva(
codReserva int not null primary key(codReserva) identity(1,1),
hospede int not null references Hospede(codHospede),
Apart int not null references Apartamento(codApart),
dataCheck_int datetime not null,
datacheck_out datetime not null,
statusReserva char(1) not null check (statusReserva in('R', 'O', 'C')),
transferidos bit default 0,
obsHospedagem varchar(100),
numerosHospedes smallint not null,
pago money not null default 0,
credito money default 0);

create table Hospedagem(
codReserva int not null primary key(codReserva),
dataEntrada datetime not null,
dataSaida datetime,
multa decimal default 0,
foreign key (codReserva) references Reserva(codReserva));

create table Transferidos(
codigo int not null, primary key(codigo), 
codApart int not null,
data date not null,
foreign key (codigo) references Reserva(codReserva));

create table Frigobar(
codigo int not null references Apartamento(codApart),
tipo varchar(30) not null,
preco money not null,
stock smallint not null);

create table Consumos(
codReserva int references Hospedagem(codReserva),
produto varchar(30) not null,
preco money not null,
consumidos int);


create table InsertedCod(cod int not null);
create table InsertedApart(apart int not null);


--Procedimentos
create procedure AddHospedes
@id varchar(10), @nome varchar(50), @sexo char(1), @morada varchar(100), @codPostal varchar(8), @local varchar(20),
@telefone varchar(9), @email varchar(100), @dataNasc date as
if not exists(select * from Pessoa where Pessoa.id = @id) 
begin
	insert into Pessoa values(@id, @nome, @sexo, @morada, @codPostal,@local, @telefone, @email, @dataNasc)
end
insert into Hospede values(@id);

create procedure AddFuncionarios
@id varchar(10), @nome varchar(50), @sexo char(1), @morada varchar(100), @codPostal varchar(20), @local varchar(20),
@telefone varchar(9), @email varchar(100), @dataNasc date, @depart varchar(20), @cargo varchar(20), @salario money as
if not exists(select * from Pessoa where Pessoa.id = @id) 
begin
	insert into Pessoa values(@id, @nome, @sexo, @morada, @codPostal,@local, @telefone, @email, @dataNasc)
end
insert into Funcionarios values(@id, @depart, @cargo, getdate(), @salario);



alter procedure AddReserva @hospede int, @apart int, @check_in datetime, @check_out datetime,
@obs varchar(100), @num int as
if exists (select disponivel from Apartamento where codApart = @apart and Apartamento.disponivel = 1 and Apartamento.limpo = 1)
begin
	declare @total money
	declare @desc int = (select descontos from Hospede where codHospede = @hospede)
	set @total = (select precoDia*datediff(day, @check_in, @check_in)-descontos/100*precoDia*datediff(day, @check_in, @check_in) 
				from Apartamento, Hospede
				where Apartamento.codApart = @apart and Hospede.codHospede = @hospede)
	insert into Reserva values(@hospede, @apart, @check_in, @check_out, 'R', 0, @obs, @num, @total, 0)
	exec UpdateDisponivel @apart
	exec AlterarDescontos @hospede;
end

create procedure AlterarDescontos @hospede int as
update Hospede 
set descontos = 0
where codHospede = @hospede

create procedure UpdateDisponivel @apart int as
update Apartamento
set disponivel = 0
where codApart = @apart

create procedure AddCkechIn @cod int as
if exists (select * from Reserva where dataCheck_int >= getdate() and codReserva = @cod)
begin
	insert into InsertedCod(cod) values (@cod)
	insert into Hospedagem(codReserva, dataEntrada) values (@cod, getdate());
	exec AddConsumos @cod
end

create trigger UpdateStatus on Hospedagem after insert as
update Reserva
set statusReserva = 'O'
where codReserva = (select cod from InsertedCod);
delete from InsertedCod;

create procedure AddConsumos @cod int as
insert into Consumos values(@cod, 'Sumo', 1.80, 0)
insert into Consumos values(@cod, 'Cerveja', 1.80, 0)
insert into Consumos values(@cod, 'Biscoito', 1.80, 0)
insert into Consumos values(@cod, 'Agua', 1.80, 0)

create procedure UpdateConsumos @agua int, @sumo int, @cerveja int, @biscoito int as
exec UpdateConsumosAgua @agua
exec UpdateConsumosSumo @sumo
exec UpdateConsumosoCerveja @cerveja
exec UpdateConsumosBiscoito @biscoito;

create procedure UpdateConsumosAgua @quant int as
update Consumos
set consumidos += @quant
where produto = 'Agua'

create procedure UpdateConsumosSumo @quant int as
update Consumos
set consumidos += @quant
where produto = 'Sumo'

create procedure UpdateConsumosoCerveja @quant int as
update Consumos
set consumidos += @quant
where produto = 'Cerveja'

create procedure UpdateConsumosBiscoito @quant int as
update Consumos
set consumidos += @quant
where produto = 'Biscoito'



create procedure AddTransferencia @cod int, @apart int, @hos int as
declare @ap int = (select Apart from Reserva where codReserva = @cod)
insert into InsertedCod(cod) values (@cod)
insert into InsertedApart(apart) values (@apart)
exec LimparQuarto @ap
exec AcertarContar @cod, @ap, @apart
exec UpdateDisponivel @ap
insert into Transferidos values(@cod, @ap, getdate());

create trigger UpdateEstado on Transferidos after insert as	
update Reserva
set transferidos = 1,
Apart = (select apart from InsertedApart)
where codReserva = (select cod from InsertedCod)
delete from InsertedApart
delete from InsertedCod;

create procedure AcertarContar @cod int, @ant int, @novo int as
Update Reserva
set credito = pago - ((select precoDia*datediff(day, dataCheck_int, getdate()) from Apartamento, Reserva 
where codApart = @ant and Reserva.Apart = Apartamento.codApart)+(select precoDia*datediff(day, getdate(), datacheck_out) from Apartamento, Reserva 
where codApart = @novo and Reserva.codReserva = @cod))
where codReserva = @cod;

create procedure LimparQuarto @apart int as
update Apartamento
set limpo = 0
where codApart = @apart;

create procedure QuartoLimpo @apart int as
update Apartamento
set limpo = 1,
disponivel = 1
where codApart = @apart;
                                                                                                                                                       

--para fazer checkout
alter procedure AddCheckOuts @codigo int, @apart int as
insert into InsertedCod values(@codigo)
update Reserva
set statusReserva = 'C',
credito += (select sum(preco*consumidos) from Consumos where codReserva = @codigo)
where codReserva = @codigo
exec LimparQuarto @apart;

select *from Consumos
select *  from Reserva
exec AddCheckOuts 2, 5;
exec AddCheckOuts 1, 1

create trigger CloseEstadia on Reserva after update as
declare @cod int = (select cod from InsertedCod)
update Hospedagem
set dataSaida = GETDATE(),
multa = datediff(day, getdate(), (select datacheck_out from Reserva where codReserva = @cod))
where codReserva = @cod
delete from InsertedCod;

insert into Consumos values(1, 'Sumo', 1.80, 5)
insert into Consumos values(1, 'Agua', 1.80, 5)
insert into Consumos values(1, 'Cerveja', 1.80, 2)
insert into Consumos values(1, 'Biscoito', 1.80, 10)


create procedure ClassificarHotel @hospede int, @pontos decimal(2,1) as
insert into Hotel values(@hospede, @pontos)


exec ClassificarHotel 1, 4.2
exec ClassificarHotel 2, 3.5
exec ClassificarHotel 3, 2.1
exec ClassificarHotel 1, 5

create procedure ShowClassificacao as
select AVG(classificacao) as Classificação from Hotel

create procedure PesquisarHospedes @cod varchar(10) as 
select nome, Pessoa.id, morada, codPostal, localidade, email, dataNasc, descontos
from Hospede, Pessoa
where Hospede.id = Pessoa.id  and Hospede.codHospede = @cod

exec PesquisarHospedes 2


create procedure PesquisarFuncionarios @cod int as
select codFun, nome, Pessoa.id, morada, codPostal, localidade, telefone, email, dataNasc, depart, cargo, dataAdmissao, salario
from Funcionarios, Pessoa
where Funcionarios.id = Pessoa.id and @cod = Funcionarios.codFun;

exec PesquisarFuncionarios 1

create procedure PesquisarReserva @cod int as
select * from Reserva where codReserva = @cod;

create procedure ReservasHoje as
select * from Reserva where dataCheck_int = (select convert (date, getdate()));

create procedure CheckoutHoje as
select * from Reserva where dataCheck_out = getdate();


create procedure RelatoriosEstatisticos as
select MAX(pago) as Maior_Gasto, Min(pago) as Menor_Gasyo, AVG(pago) as Media_Gasto, Sum(pago) as Gasto_Total
from Reserva

create procedure TotalTransferencia as
select count(*) as Total_Transferencia from Reserva where transferidos = 1

Create procedure TopReservas as
select Top(5) codReserva, nome, pago
from Reserva, Pessoa, Hospede
where Reserva.hospede = hospede.codHospede and hospede.id = Pessoa.id
order by pago DESC



select * from Reserva




---Executando os codigos

--adicionar hospedes
exec AddHospedes 'a48342', 'dania', 'F', 'largo dos descobrimentos', '5370-343', 'Mirandela', '92343256', 'a48342@alunos.ipb.pt', '1997-07-27'; 
exec AddHospedes 'a24254', 'vanisia', 'F', 'Rua Sr dos aflitos', '5370-343', 'Mirandela', '93456823', 'a24254@alunos.ipb.pt', '1987-08-01'; 
exec AddHospedes 'a23543', 'edney', 'M', 'avenida dos bombeiros', '5370-421', 'Mirandela', '97324212', 'a23543@alunos.ipb.pt', '1999-10-02'; 
exec AddHospedes 'a65822', 'Redney', 'M', 'avenida dos bombeiros', '5370-444', 'Mirandela', '97324324', 'a65822@alunos.ipb.pt', '1999-10-02'; 
select * from Hospede
--adicionar departamento
exec AddDepartamento 'adminstração';
exec AddDepartamento 'contabilidade';
exec AddDepartamento 'TI';
exec AddDepartamento 'marketing';

--adicionar funcionarios
exec AddFuncionarios 'a34324', 'kiki', 'M', 'rua garcia orta 20', '2342-323', 'Cruz Pau', '92441243', 'kiki@jurele.com', '1988-09-22', 'adminstração', 'Adminstrador', 1230.89;
exec AddFuncionarios 'a39488', 'tais', 'F', 'rua dos ecliptos', '2343-523', 'Laranjeiro', '96231433', 'tais@jurele.com', '1991', 'TI', 'Analise de sistemas', 1023.4;

--adicionar tipoapartamento
exec AddTipoApart 'modernos';
exec AddTipoApart 'luxuosos';
exec AddTipoApart 'economicos';

--adicinar apartamento
exec AddApartamento '2A', 'modernos', 2, 180;
exec AddApartamento '2C', 'economicos', 3, 150;
exec AddApartamento '5A', 'modernos', 2, 180;
exec AddApartamento '7A', 'luxuosos', 1, 390;
exec AddApartamento '7B', 'luxuosos', 1, 390;
exec AddApartamento '2D', 'economicos', 1, 80;

--adicionar uma reserva
exec AddReserva 1, 1, '2022-01-06', '2022-01-15', '', 3;
exec AddReserva 1, 2, '2022-01-02', '2022-01-16', '', 2;
exec AddReserva 2, 3, '2022-01-10', '2022-01-16', '', 2;
exec AddReserva 3, 4, '2022-01-20', '2022-01-16', '', 3;
exec AddReserva 2, 5, '2022-01-13', '2022-01-20', '', 2;
exec AddReserva 3, 43, '2022-01-15', '2022-01-28', '', 2;
select * from Hospede
---Adicionar CheckIn
exec AddCkechIn 4;

select * from Reserva
exec AddCkechIn 3;

select * from Reserva, Hospedagem where Reserva.codReserva = Hospedagem.codReserva


--adicionar transferencia 3060
exec AddTransferencia  2; 

--limpar quarto
exec QuartoLimpo 4

use Hotel

---Adicionar Transferencia
exec AddTransferencia 2, 5, 1;
exec AddTransferencia 3, 5, 2

---adicionar checkout
exec AddCheckOuts 4, 4;



use Hotel
update Apartamento
set disponivel 


select * from Hospede
select * from Apartamento
select * from Reserva


update Hospede
set descontos = 20
where codHospede = 1

select precoDia*datediff(day, dataCheck_int, datacheck_out)-descontos/100*precoDia*datediff(day, dataCheck_int, datacheck_out) 
from Apartamento, Reserva, Hospede
where Reserva.Apart = Apartamento.codApart and Hospede.codHospede = Reserva.hospede


(select precoDia from Apartamento where codApart = @apart)*datediff(day, @check_in, @check_out)-(@desc/100*
(select precoDia from Apartamento where codApart = @apart)*datediff(day, @check_in, @check_out))


((select precoDia*datediff(day, dataCheck_int, getdate()) from Apartamento, Reserva 
where codApart = @ant and Reserva.Apart = Apartamento.codApart)+

(select precoDia*datediff(day, getdate(), datacheck_out) from Apartamento, Reserva 
where codApart = @novo and Reserva.codReserva = @cod)


