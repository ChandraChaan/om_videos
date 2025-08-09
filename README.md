📱 Flutter App README

Title:
OM Video Uploader (Flutter)

Description:
A Flutter-based mobile application for uploading large video files to a server with resumable upload support. Designed for team collaboration on YouTube projects — editors can upload videos even with slow or unstable internet connections, resuming from where they left off.

Key Features:
•	Chunked file upload (split large files into small parts, e.g., 5 MB chunks).
•	Resume uploads if interrupted.
•	Real-time upload progress bar.
•	Authentication (Editor login).
•	Upload history view.
•	Option to retry failed chunks.

Dependencies:
•	dio (for upload with progress)
•	shared_preferences (for storing user login)
•	path_provider (to access file paths)
•	file_picker (to select video files)