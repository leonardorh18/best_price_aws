import boto3
import requests
from bs4 import BeautifulSoup

# URL da página que você deseja extrair os links
search = 'monitor 144hz'
search = search.replace(" ", "+")
url = f'https://www.terabyteshop.com.br/busca?str={search}'
print(f"buscando...{url}")
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'}

from bs4 import BeautifulSoup
from selenium import webdriver
driver = webdriver.Chrome()
driver.get(url)
html = driver.page_source
soup = BeautifulSoup(html)
items = soup.find_all('div', class_= "pbox col-xs-12 col-sm-6 col-md-3 col-lg-1-5")

# Itere sobre os links e imprima o texto e o atributo href de cada um
for item in items:
    print(item.get("title"))

