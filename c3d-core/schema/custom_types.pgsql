CREATE TYPE link AS (title text, url text);
CREATE TYPE gender AS ENUM ('male', 'female', 'other');
CREATE TYPE event_role AS ENUM('coordinator', 'submitter', 'speaker', 'moderator', 'herald', 'video-camera', 'video-mixer', 'video-cutter', 'video-checker');