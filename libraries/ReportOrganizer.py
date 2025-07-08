import os
import shutil
from datetime import datetime

class ReportOrganizer:
    ROBOT_LISTENER_API_VERSION = 3 # Updated for modern Robot Framework versions

    def __init__(self):
        print("--- ReportOrganizer Listener Initialized ---")

    def close(self):
        print("--- ReportOrganizer close() method called ---")
        try:
            from robot.libraries.BuiltIn import BuiltIn
            
            # Get the directory where the output files were generated
            output_dir = BuiltIn().get_variable_value('${OUTPUTDIR}')
            
            # In modern RF, these variables usually give absolute paths.
            # If not, joining with output_dir is a safe fallback.
            log_file = BuiltIn().get_variable_value('${LOGFILE}')
            report_file = BuiltIn().get_variable_value('${REPORTFILE}')
            output_file = BuiltIn().get_variable_value('${OUTPUTFILE}')

            if not os.path.isabs(log_file):
                log_file = os.path.join(output_dir, log_file)
            if not os.path.isabs(report_file):
                report_file = os.path.join(output_dir, report_file)
            if not os.path.isabs(output_file):
                output_file = os.path.join(output_dir, output_file)

            print(f"Detected output directory: {output_dir}")
            print(f"Log file path: {log_file}")
            print(f"Report file path: {report_file}")
            print(f"Output file path: {output_file}")

            # Define the new directory for the reports, located at the project root
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
            results_base_dir = os.path.join(project_root, 'results')
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            new_report_dir = os.path.join(results_base_dir, f'run_{timestamp}')
            
            os.makedirs(new_report_dir, exist_ok=True)
            print(f"New report directory created: {new_report_dir}")

            # Move the files
            for file_path in [log_file, report_file, output_file]:
                if file_path and os.path.exists(file_path):
                    print(f"Moving {os.path.basename(file_path)} to {new_report_dir}")
                    shutil.move(file_path, new_report_dir)
                else:
                    print(f"File not found or path is invalid, skipping: {file_path}")
            
            print("--- Report organization complete ---")

        except Exception as e:
            print(f"!!! ERROR in ReportOrganizer: {e} !!!")