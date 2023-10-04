FROM python:3.9

RUN apt-get -y update
RUN pip install --upgrade pip
RUN apt-get install zip -y
RUN apt-get install unzip -y

# Install chromedriver
RUN wget -N https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/117.0.5938.92/linux64/chromedriver-linux64.zip -P ~/
#RUN wget -N https://chromedriver.storage.googleapis.com/72.0.3626.69/chromedriver_linux64.zip -P ~/
RUN unzip ~/chromedriver-linux64.zip -d ~/
RUN rm ~/chromedriver-linux64.zip
RUN mv -f ~/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
RUN chown root:root /usr/local/bin/chromedriver
RUN chmod 0755 /usr/local/bin/chromedriver


# Install chrome broswer
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -y update
RUN apt-get -y install google-chrome-stable

# upgrade pip
RUN pip install --upgrade pip

# Crie um diretório de trabalho dentro do contêiner
WORKDIR /app

COPY src/* /app/

# Instale as bibliotecas Python usando pip
RUN pip install polars requests beautifulsoup4 selenium boto3

# Define o comando padrão para executar quando o contêiner for iniciado
CMD ["python", "main.py"]