import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
import pandas as pd

def execute_sql_query(env_path: str, sql_file_path: str) -> pd.DataFrame:
    load_dotenv(env_path)
    user = os.getenv('MYSQL_USER')
    password = os.getenv('MYSQL_PASSWORD')
    host = os.getenv('MYSQL_HOST')
    db = os.getenv('MYSQL_DB')

    conn_text = f'mysql+pymysql://{user}:{password}@{host}/{db}'
    engine = create_engine(conn_text)

    with open(sql_file_path, 'r') as file:
        sql_query = file.read().replace('use caris_db;', '')

    df = pd.read_sql_query(sql_query, engine)
    engine.dispose()

    return df

#===========================================================================================================================
#========================================================================================================================= 
import os
from dotenv import load_dotenv
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import time
from datetime import datetime

def download_files():
    load_dotenv('id_cc.env')
    email = os.getenv('EMAIL')
    password_cc = os.getenv('PASSWORD')

    options = Options()
    options.add_argument("start-maximized")
    prefs = {"download.default_directory": "C:\\Users\\Moise\\Downloads\\Reports_MEAL\\COMMCARE\\OEV"}
    options.add_experimental_option("prefs", prefs)

    driver = webdriver.Chrome(options=options)
    driver.implicitly_wait(1000)

    def commcare_login():
        try:
            driver.get('https://www.commcarehq.org/a/caris-test/data/export/custom/new/case/download/f6ddce2133f8d233d9fbd9341220ed6f/')
            driver.find_element(By.XPATH, '//*[@id="id_auth-username"]').send_keys(email)
            driver.find_element(By.XPATH, '//*[@id="id_auth-password"]').send_keys(password_cc)
            driver.find_element(By.CSS_SELECTOR, 'button[type=submit]').click()
        except Exception as e:
            print(f"An error occurred during login: {e}")

    def download_report(download_url, button_xpath, progress_xpath):
        try:
            driver.get(download_url)
            driver.find_element(By.XPATH, button_xpath).click()
            time.sleep(80)  # wait for download to start
            driver.find_element(By.XPATH, progress_xpath).click()
        except Exception as e:
            print(f"An error occurred while downloading from {download_url}: {e}")

    commcare_login()

    # Get the current date in the format YYYY-MM-DD
    today_date = datetime.today().strftime('%Y-%m-%d')

    download_report(
        'https://www.commcarehq.org/a/caris-test/data/export/custom/new/case/download/f6ddce2133f8d233d9fbd9341220ed6f/',
        '//*[@id="download-export-form"]/form/div[2]/div/div[2]/div[1]/button/span[1]',
        '//*[@id="download-progress"]/div/div/div[2]/div[1]/form/a/span[1]'
    )

    download_report(
        'https://www.commcarehq.org/a/caris-test/data/export/custom/new/form/download/378b3552e10aa41ea62f069ee0b312d3/',
        '//*[@id="download-export-form"]/form/div[2]/div/div[2]/div[1]/button/span[1]',
        '//*[@id="download-progress"]/div/div/div[2]/div[1]/form/a/span[1]'
    )

    download_report(
        'https://www.commcarehq.org/a/caris-test/data/export/custom/new/form/download/d24fc1a47af7508393152bf966a22f99/',
        '//*[@id="download-export-form"]/form/div[2]/div/div[2]/div[1]/button/span[1]',
        '//*[@id="download-progress"]/div/div/div[2]/div[1]/form/a/span[1]'
    )

    download_report(
        'https://www.commcarehq.org/a/caris-test/data/export/custom/new/case/download/0379abcdafdf9979863c2d634792b5a8/',
        '//*[@id="download-export-form"]/form/div[2]/div/div[2]/div[1]/button/span[1]',
        '//*[@id="download-progress"]/div/div/div[2]/div[1]/form/a/span[1]'
    )

    # Check if the last file is completely downloaded before quitting
    last_file = f'household_child {today_date}.xlsx'
    download_path = os.path.join("C:\\Users\\Moise\\Downloads\\Reports_MEAL\\OEV", last_file)

    # Wait for the last file to appear in the download directory
    timeout = 300  # seconds
    start_time = time.time()
    while not os.path.isfile(download_path):
        if time.time() - start_time > timeout:
            print(f"Timed out waiting for the file {last_file} to download.")
            break
        time.sleep(5)

    driver.quit()

#===================================================================================================================
def check_files(files):
    path = "C:\\Users\\Moise\\Downloads\\Reports_MEAL\\OEV"
    missing_files = []

    for file in files:
        full_path = os.path.join(path, file)
        print(f"Checking for file: {full_path}")  # Debugging print
        if not os.path.isfile(full_path):
            missing_files.append(file)

    if not missing_files:
        print("All files are present.")
    else:
        print(f"The following files are missing: {missing_files}")

# Get the current date in the format YYYY-MM-DD
today_date = datetime.today().strftime('%Y-%m-%d')
#==================================================================================================================
