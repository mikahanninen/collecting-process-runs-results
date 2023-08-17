import sqlite3

class SQLiteDatabase:
    def __init__(self):
        self.connection = None
        self.cursor = None

    def connect(self, database_file):
        self.connection = sqlite3.connect(database_file)
        self.cursor = self.connection.cursor()

    def create_process_runs_database(self, database_file):
        self.connect(database_file)
        create_table_sql = """
        CREATE TABLE processes (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            workspaceId TEXT NOT NULL
        );
        """
        # execute the SQL statement
        self.cursor.execute(create_table_sql)
        self.connection.commit()
        create_table_sql = """
        CREATE TABLE process_runs (
            process_id TEXT PRIMARY KEY NOT NULL,
            process_run_id TEXT NOT NULL,
            runNo INTEGER NOT NULL,
            result TEXT NOT NULL,
            state TEXT NOT NULL,
            duration INTEGER NOT NULL,
            startTs TEXT NOT NULL,
            endTs TEXT NOT NULL
        );
        """
        # execute the SQL statement
        self.cursor.execute(create_table_sql)
        self.connection.commit()

    def execute_query(self, query: str, results: bool = False):
        # Execute the SQL statement
        self.cursor.execute(query)
        self.connection.commit()
        return self.cursor.fetchall() if results else None