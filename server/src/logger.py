import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path
import sys
import datetime

class Logger:
    def __init__(self, log_dir="logs", log_filename="app.log", max_bytes=5*1024*1024, backup_count=3):
        """
        Initializes the logger.
        :param log_dir: Directory where logs are stored.
        :param log_filename: Base name of the log file.
        :param max_bytes: Max size of a log file before rotation (default 5MB).
        :param backup_count: Number of backup files to keep.
        """
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.log_path = self.log_dir / log_filename

        # Create a custom logger
        self.logger = logging.getLogger("FastAPI_App")
        self.logger.setLevel(logging.DEBUG)

        # Avoid adding handlers multiple times if logger is reused
        if not self.logger.hasHandlers():
            self._setup_handlers(max_bytes, backup_count)

    def _setup_handlers(self, max_bytes, backup_count):
        # 1. Format: Time - Level - Message
        formatter = logging.Formatter(
            fmt="[%(asctime)s] [%(levelname)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )

        # 2. File Handler (With Rotation)
        # Automatically creates new file when current one reaches 5MB
        file_handler = RotatingFileHandler(
            self.log_path,
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.INFO) # Save INFO and above to file

        # 3. Console Handler (Stream)
        # Prints logs to your terminal (Docker/Systemd needs this)
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        console_handler.setLevel(logging.DEBUG) # Show everything in console

        # Add handlers to logger
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)

    def get_logger(self):
        return self.logger

# Create a singleton instance
app_logger_instance = Logger(
    log_dir="logs",
    log_filename=f"log_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log"
)
logger = app_logger_instance.get_logger()