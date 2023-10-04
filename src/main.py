import boto3
from datetime import datetime
from bs4 import BeautifulSoup
import polars as pl
import os, uuid, sys
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
import re

SEARCH = os.environ['SEARCH']
BUCKET = os.environ['BUCKET_NAME']
AWS_ACCESS_KEY = os.environ['AWS_ACCESS_KEY']
AWS_SECRET_KEY = os.environ['AWS_SECRET_KEY']
AWS_REGION = os.environ['AWS_REGION']
TOPIC_ARN = os.environ['TOPIC_ARN']

def get_driver():
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--headless')
        chrome_options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36')
        chrome_options.add_experimental_option(
            "prefs",
            {
                'profile.managed_default_content_settings.javascript':2
            }
        )
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument("--window-size=1920,1080")
        driver = webdriver.Chrome(options=chrome_options)
        return driver
    
    
def save_file(df, session):
    s3 = session.client('s3')
    today = datetime.today()
    file_name = f"{uuid.uuid1()}.parquet"
    path = today.strftime("%Y/%m/%d/")
    df.write_parquet(file_name)
   
    # Conectar-se ao serviço S3 usando boto3
    s3 = session.client('s3')

    # Fazer o upload do arquivo Parquet para o bucket S3
    s3.upload_file(
        file_name,
        BUCKET,
        f"{path}{file_name}"
    )
    os.remove(file_name)
    print("UPLOAD S3 CONCLUIDO!")

def get_product_info(items):
    data = {
        "title": [],
        "link": [],
        "old_price": [],
        "new_price": [],
        "juros": []
    }
    for item in items:
        try:
            data["title"].append(item.find('a', class_='prod-name')['title'])
        except:
            data["title"].append('')
        try:
            data["link"].append(item.find('a', class_='prod-name')['href'])
        except:
            data["link"].append('')
        try:
            data["old_price"].append(item.find('div', class_ = 'prod-old-price').span.text)
        except:
            data["old_price"].append('')
        try: 
            data["new_price"].append(item.find('div', class_ = 'prod-new-price').span.text)
        except:
            data["new_price"].append('')
        try:
            data["juros"].append(item.find('div', class_ = 'prod-juros').text)
        except:
            data["juros"].append('')
    return data

def get_price(price):
    try:
        # Defina um padrão de regex para encontrar os números no formato R$ X.XXX,XX
        pattern = r'R\$ (\d{1,3}(?:\.\d{3})*(?:,\d{2}))'

        # Use o método findall() para encontrar todas as correspondências ao padrão
        price = re.findall(pattern , price)

        # Função auxiliar para transformar a correspondência em float
        def to_float(match):
            return float(match.replace('.', '').replace(',', '.'))

        # Transforme as correspondências em floats
        return to_float(price[0])
    except:
        return None
    
def publish_email(session, df):
    PRICE_LIMIT = float(os.environ['PRICE_LIMIT'])

    subject = 'Alerta de Preço!'


    df = df.with_columns((df['new_price'].apply(lambda x: get_price(x))).alias('price'))
    message = 'O(s) item(s) abaixo estão com o preço que você quer!! \n'
    for row in df.filter(df['price'] <= PRICE_LIMIT).iter_rows():
        new_message = f"\n \t O item {row[0]} está saindo por {row[3]}. Disponível em {row[1]} \n"
        message = message + new_message
    print(message)

    sns = session.client('sns')
    # Publique a mensagem no tópico
    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=subject,
        Message=message
    )

    print('Mensagem publicada com sucesso.')

if __name__ == "__main__":
    # URL da página que você deseja extrair os links

    session = boto3.Session(
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
        region_name= AWS_REGION,
    )
    search = SEARCH.replace(" ", "+")
    url = f'https://www.terabyteshop.com.br/busca?str={search}'

    print(f"buscando...{url}")
    driver = get_driver()
    driver.get(url)
    html = driver.page_source
    print('html')
    print(html)
    soup = BeautifulSoup(html)
    items = soup.find_all('div', class_= "pbox col-xs-12 col-sm-6 col-md-3 col-lg-1-5")
    print(f"items ============ {items}")
    data = get_product_info(items)
    print(data)
    print("PRODUTOS LIDOS COM SUCESSO!")
    df = pl.DataFrame(data)
    save_file(df, session)
    publish_email(session, df)
    sys.exit(0)
