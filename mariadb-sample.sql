mysql -u root

drop table if exists test;
create database test;

use test;
CREATE user 'user'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON * . * TO 'user'@'%';

CREATE TABLE IF NOT EXISTS people (
    p_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)  ENGINE=INNODB;

insert into people values(null, "Kirk", "Van Houten", "Can I Borrow A Feeling", null);
insert into people values(null, "Luanne", "Van Houten", "The other day Milhouse told me my meatloaf sucks. He must have gotten that from your little boy because they certainly don't say that word on TV.", null);
insert into people values(null, "Milhouse", "Van Houten", "THRILLHO", null);
insert into people values(null, "Homer", "Simpson", "Doh!", null);
insert into people values(null, "Marge", "Simpson", "hmmmmmmmm", null);
insert into people values(null, "Bart", "Simpson", "Ay Caramba!", null);
insert into people values(null, "Lisa", "Simpson", "The smart one", null);
insert into people values(null, "Maggie", "Simpson", "The baby", null);
insert into people values(null, "Clancy", "Wiggum", "The Chief", null);
insert into people values(null, "Sarah", "Wiggum", "Ralph's mom", null);
insert into people values(null, "Ralph", "Wiggum", "Taste like burning", null);
