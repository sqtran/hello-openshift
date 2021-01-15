psql

create USER "user" with password 'password';

create database test;
\c test;

CREATE TABLE IF NOT EXISTS people (
    p_id serial,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    description text,
    created_at timestamp default (now() at time zone 'utc')
);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "user";

insert into people (first_name, last_name, description) values('Kirk', 'Van Houten', 'Can I Borrow A Feeling');
insert into people (first_name, last_name, description) values('Luanne', 'Van Houten', 'The other day Milhouse told me my meatloaf sucks. He must have gotten that from your little boy because they certainly donr''t say that word on TV.');
insert into people (first_name, last_name, description) values('Milhouse', 'Van Houten', 'THRILLHO');
insert into people (first_name, last_name, description) values('Homer', 'Simpson', 'Doh!');
insert into people (first_name, last_name, description) values('Marge', 'Simpson', 'hmmmmmmmm');
insert into people (first_name, last_name, description) values('Bart', 'Simpson', 'Ay Caramba!');
insert into people (first_name, last_name, description) values('Lisa', 'Simpson', 'The smart one');
insert into people (first_name, last_name, description) values('Maggie', 'Simpson', 'The baby');
insert into people (first_name, last_name, description) values('Clancy', 'Wiggum', 'The Chief');
insert into people (first_name, last_name, description) values('Sarah', 'Wiggum', 'Ralph''s mom');
insert into people (first_name, last_name, description) values('Ralph', 'Wiggum', 'Taste like burning');

