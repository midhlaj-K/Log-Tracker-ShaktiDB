-- ==========================================================
-- Sample Data
-- ==========================================================

-------------------------------------------------------------
-- Access Groups
-------------------------------------------------------------

INSERT INTO access_group (group_name)
VALUES
('Development'),
('Research'),
('Testing');


-------------------------------------------------------------
-- Users
-------------------------------------------------------------

INSERT INTO app_user
(username,password_hash,role,group_id)

VALUES

('root','root123','root',1),

('Midhlaj','mid123','admin',1),

('Minhaj','min123','user',1),

('Katie','kat123','user',1),

('Michael','mic123','admin',2),

('Parthiv','par123','user',2),

('Vyshnav','vys123','user',2),

('Navya','nav123','user',3),

('Nandhana','nan123','user',3);


-------------------------------------------------------------
-- Directories
-------------------------------------------------------------

INSERT INTO directory
(directory_name,full_path,owner,parent_directory)

VALUES

('root','/root',1,NULL),

('midhlaj','/home/Midhlaj',2,NULL),

('documents','/home/Midhlaj/Documents',2,2),

('minhaj','/home/Minhaj',3,NULL),

('katie','/home/Katie',4,NULL),

('michael','/home/Michael',5,NULL),

('parthiv','/home/Parthiv',6,NULL),

('vyshnav','/home/Vyshnav',7,NULL),

('navya','/home/Navya',8,NULL),

('nandhana','/home/Nandhana',9,NULL);


-------------------------------------------------------------
-- Files
-------------------------------------------------------------

INSERT INTO file_entry
(

file_name,

extension,

owner,

directory_id,

file_size

)

VALUES

('report','pdf',2,3,250000),

('notes','txt',2,3,1200),

('database','sql',3,4,8500),

('project','zip',4,5,1800000),

('budget','xlsx',5,6,65000),

('presentation','pptx',6,7,980000),

('photo','jpg',7,8,2400000),

('resume','pdf',8,9,450000),

('readme','md',9,10,2500);


-------------------------------------------------------------
-- Sample Logs
-------------------------------------------------------------

SELECT insert_log(

1,

'login',

'user',

1,

'{
    "ip":"127.0.0.1"
}'::jsonb

);

SELECT insert_log(

2,

'created',

'file',

1,

'{
    "file":"report.pdf"
}'::jsonb

);

SELECT insert_log(

2,

'renamed',

'file',

2,

'{
    "old_name":"notes.txt",
    "new_name":"lecture_notes.txt"
}'::jsonb

);

SELECT insert_log(

3,

'updated',

'file',

3,

'{
    "size_before":8000,
    "size_after":8500
}'::jsonb

);

SELECT insert_log(

5,

'created',

'user',

8,

'{
    "username":"Navya"
}'::jsonb

);

SELECT insert_log(

1,

'updated',

'user',

5,

'{
    "old_role":"user",
    "new_role":"admin"
}'::jsonb

);

SELECT insert_log(

2,

'deleted',

'file',

4,

'{
    "file":"project.zip"
}'::jsonb

);

SELECT insert_log(

7,

'logout',

'user',

7,

'{
    "session":"ended"
}'::jsonb

);
