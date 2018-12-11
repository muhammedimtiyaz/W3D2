PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname VARCHAR(40) NOT NULL,
    lname VARCHAR(40) NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_reply_id INTEGER,
    
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    ('Cameron', 'Couch'),
    ('Muhammed', 'Imtiyaz');

INSERT INTO
    questions (title, body, user_id)
VALUES
    ('How does sql work?', 'Seriously, how does it work?', (SELECT id FROM users WHERE fname='Cameron')),
    ('what''s your name?', 'what IS your name?', 2),
    ('my question', 'what is a good question?', 1);

INSERT INTO
    question_follows(user_id, question_id)
VALUES
    ((SELECT id FROM users WHERE fname = 'Cameron'), (SELECT id FROM questions WHERE title = 'How does sql work?')),
    (1,2),
    (2,2);

INSERT INTO
    replies(body, user_id, question_id, parent_reply_id)
VALUES
    ('I don''t know either.', 2, 1, NULL);

INSERT INTO
    question_likes(user_id, question_id)
VALUES
    (1,1),
    (2,1);
