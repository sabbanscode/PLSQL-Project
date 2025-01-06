--This schema includes tables to manage teams, players, matches, and scores.

CREATE TABLE Teams ( TeamID INT PRIMARY KEY, TeamName VARCHAR(100) NOT NULL, TotalPoints INT DEFAULT 0);

CREATE TABLE Players ( PlayerID INT PRIMARY KEY, PlayerName VARCHAR(100) NOT NULL, TeamID INT, GoalsScored INT DEFAULT 0, Assists INT DEFAULT 0, MatchesPlayed INT DEFAULT 0,
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID));

CREATE TABLE Matches ( MatchID INT PRIMARY KEY, Team1ID INT, Team2ID INT, Team1Score INT DEFAULT 0, Team2Score INT DEFAULT 0, MatchDate DATE, FOREIGN KEY (Team1ID) REFERENCES Teams(TeamID),
    FOREIGN KEY (Team2ID) REFERENCES Teams(TeamID));

CREATE TABLE PointsTable ( TeamID INT PRIMARY KEY, MatchesPlayed INT DEFAULT 0, Wins INT DEFAULT 0, Draws INT DEFAULT 0, Losses INT DEFAULT 0, Points INT DEFAULT 0,
    FOREIGN KEY (TeamID) REFERENCES Teams(TeamID));

--Insert Teams

INSERT INTO Teams (TeamID, TeamName) VALUES (1, 'Team A');
INSERT INTO Teams (TeamID, TeamName) VALUES (2, 'Team B');
INSERT INTO Teams (TeamID, TeamName) VALUES (3, 'Team C');
INSERT INTO Teams (TeamID, TeamName) VALUES (4, 'Team D');


--Insert Players

INSERT INTO Players (PlayerID, PlayerName, TeamID) VALUES (1, 'Player 1', 1);
INSERT INTO Players (PlayerID, PlayerName, TeamID) VALUES (2, 'Player 2', 1);
INSERT INTO Players (PlayerID, PlayerName, TeamID) VALUES (3, 'Player 3', 2);
INSERT INTO Players (PlayerID, PlayerName, TeamID) VALUES (4, 'Player 4', 3);


--Insert Matches

INSERT INTO Matches (MatchID, Team1ID, Team2ID, Team1Score, Team2Score, MatchDate) 
VALUES (1, 1, 2, 2, 1, DATE '2025-01-01');

INSERT INTO Matches (MatchID, Team1ID, Team2ID, Team1Score, Team2Score, MatchDate) 
VALUES (2, 3, 4, 0, 0, DATE '2025-01-02');


--Insert Points Table

INSERT INTO PointsTable (TeamID) VALUES (1);
INSERT INTO PointsTable (TeamID) VALUES (2);
INSERT INTO PointsTable (TeamID) VALUES (3);
INSERT INTO PointsTable (TeamID) VALUES (4);

select * from Teams;
select * from Players;
select * from Matches;
select * from PointsTable;

--This query calculates league standings based on the PointsTable.

SELECT T.TeamName, P.MatchesPlayed, P.Wins, P.Draws, P.Losses, P.Points FROM  PointsTable P JOIN Teams T ON P.TeamID = T.TeamID ORDER BY P.Points DESC, T.TeamName;

--procedures to calculate player statistics dynamically.

CREATE OR REPLACE PROCEDURE CalculatePlayerStats AS
BEGIN
    -- Update player statistics dynamically for all players
    FOR player_rec IN (
        SELECT PlayerID, TeamID
        FROM Players
    )
    LOOP
        -- Calculate goals scored by the player
        UPDATE Players
        SET GoalsScored = (
            SELECT NVL(SUM(M.Team1Score), 0)
            FROM Matches M
            WHERE M.Team1ID = player_rec.TeamID
        )
        WHERE PlayerID = player_rec.PlayerID;

        -- Calculate assists for the player (example logic)
        UPDATE Players
        SET Assists = (
            SELECT NVL(SUM(M.Team2Score), 0)
            FROM Matches M
            WHERE M.Team2ID = player_rec.TeamID
        )
        WHERE PlayerID = player_rec.PlayerID;

        -- Update matches played by the player
        UPDATE Players
        SET MatchesPlayed = (
            SELECT COUNT(*)
            FROM Matches M
            WHERE M.Team1ID = player_rec.TeamID OR M.Team2ID = player_rec.TeamID
        )
        WHERE PlayerID = player_rec.PlayerID;
    END LOOP;

    -- Commit changes if not in a transactional block
    COMMIT;
END;
/

execute CalculatePlayerStats;


-- Verify the updated statistics
SELECT * FROM Players;




CREATE OR REPLACE PROCEDURE UpdatePlayerStats (
    p_PlayerID IN NUMBER,
    p_GoalsScored IN NUMBER,
    p_Assists IN NUMBER
) AS
BEGIN
    UPDATE Players
    SET 
        GoalsScored = NVL(GoalsScored, 0) + p_GoalsScored,
        Assists = NVL(Assists, 0) + p_Assists,
        MatchesPlayed = NVL(MatchesPlayed, 0) + 1
    WHERE 
        PlayerID = p_PlayerID;

    -- Commit changes if not in a transactional block
    COMMIT;
END;
/


BEGIN
    UpdatePlayerStats(p_PlayerID => 1, p_GoalsScored => 2, p_Assists => 1);
END;
/

    SELECT * FROM Players WHERE PlayerID = 1;

--triggers to update match results and points table.

CREATE OR REPLACE TRIGGER AfterMatchUpdate
AFTER INSERT OR UPDATE ON Matches
FOR EACH ROW
DECLARE
    v_Team1ID INT;
    v_Team2ID INT;
    v_Team1Score INT;
    v_Team2Score INT;
BEGIN
    -- Fetch match details from the new row
    v_Team1ID := :NEW.Team1ID;
    v_Team2ID := :NEW.Team2ID;
    v_Team1Score := :NEW.Team1Score;
    v_Team2Score := :NEW.Team2Score;

    -- Update Points for Team 1
    IF v_Team1Score > v_Team2Score THEN
        UPDATE PointsTable
        SET Wins = Wins + 1, Points = Points + 3, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team1ID;
    ELSIF v_Team1Score = v_Team2Score THEN
        UPDATE PointsTable
        SET Draws = Draws + 1, Points = Points + 1, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team1ID;
    ELSE
        UPDATE PointsTable
        SET Losses = Losses + 1, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team1ID;
    END IF;

    -- Update Points for Team 2
    IF v_Team2Score > v_Team1Score THEN
        UPDATE PointsTable
        SET Wins = Wins + 1, Points = Points + 3, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team2ID;
    ELSIF v_Team2Score = v_Team1Score THEN
        UPDATE PointsTable
        SET Draws = Draws + 1, Points = Points + 1, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team2ID;
    ELSE
        UPDATE PointsTable
        SET Losses = Losses + 1, MatchesPlayed = MatchesPlayed + 1
        WHERE TeamID = v_Team2ID;
    END IF;
END;
/


INSERT INTO Matches (MatchID, Team1ID, Team2ID, Team1Score, Team2Score, MatchDate)
VALUES (3, 1, 3, 1, 1, DATE '2025-01-03');

UPDATE Matches
SET Team1Score = 2, Team2Score = 3
WHERE MatchID = 3;


SELECT * FROM PointsTable;







