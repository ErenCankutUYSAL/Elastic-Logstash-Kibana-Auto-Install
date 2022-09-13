##http://10.0.1.91:5601/app/security/overview?sourcerer=(default:!(%27filebeat-*%27))&timerange=(global:(linkTo:!(timeline),timerange:(from:%272022-04-04T21:00:00.000Z%27,fromStr:now%2Fd,kind:relative,to:%272022-04-05T20:59:59.999Z%27,toStr:now%2Fd)),timeline:(linkTo:!(global),timerange:(from:%272022-04-04T21:00:00.000Z%27,fromStr:now%2Fd,kind:relative,to:%272022-04-05T20:59:59.999Z%27,toStr:now%2Fd)))
#hostname="$(hostnamectl | awk  '{print $3}' | head -n 1)"
ipaddress="$(hostname -I)"





function packagename {
        local listpack=${1}

        ###############Elasticsearch area
        if [  "elasticsearch" == "$listpack" ] ; then
		
			 echo "$listpack"" Paketi ""$ipaddress"" adressli bilgisayara kurulum başlatıldı." >> /var/log/InstallInfo.log
             sudo timedatectl set-timezone Asia/Istanbul
             echo "Timezone Asia/Istanbul Olarak Ayarlandı." >> /var/log/InstallInfo.log
             curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
             echo "https://artifacts.elastic.co/GPG-KEY-elasticsearch urlsinden key içeriye eklendi." >> /var/log/InstallInfo.log
             echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
             echo "https://artifacts.elastic.co/packages/7.x/apt sourcle listi elasticsearche göre ayarlandı" >> /var/log/InstallInfo.log
             sudo apt update -y
             echo "update işlemi yapıldı." >> /var/log/InstallInfo.log
             sudo apt install "$listpack" -y
             echo "$ipaddress"" adressli bilgisayara elasticsearch kurulumu yapıldı." >> /var/log/InstallInfo.log
             echo "network.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
             echo "/etc/elasticsearch/elasticsearch.yml dosyasına network.host eklenerek localhost ayarlandı."  >> /var/log/InstallInfo.log
             sed -i 's/## -Xms4g/-Xms2g/g' /etc/elasticsearch/jvm.options
             sed -i 's/## -Xmx4g/-Xmx2g/g' /etc/elasticsearch/jvm.options
             echo "/etc/elasticsearch/jvm.options java ayarları 2g olarak ayarlandı." >> /var/log/InstallInfo.log
                         ####elasticsearch.url: "http://0.0.0.0:9200"
             sudo systemctl daemon-reload
             sudo systemctl start elasticsearch
             sudo systemctl enable elasticsearch
             echo "9200 portuna get komutu yollanarak test edildi."  >> /var/log/InstallInfo.log
			 echo "##############################################" >> /var/log/InstallInfo.log
             curl -X GET "localhost:9200"  >> /var/log/InstallInfo.log
			 echo "##############################################" >> /var/log/InstallInfo.log
                         ##buraya get ile okey veya olumsuz döngüsü oluşturulabilir.
	    else
			 echo "1 girilen değer elasticsearch değil."
        fi
        ###############Kibana area
        if [  "kibana" == "$listpack" ] ; then
		
			 echo "$listpack"" Paketi ""$ipaddress"" adressli bilgisayara kurulum başlatıldı." >> /var/log/InstallInfo.log
			 sudo apt install "$listpack" -y
			 sudo systemctl enable kibana 
			 sudo systemctl start kibana
			 echo "$listpack" "Başlatıldı." >> /var/log/InstallInfo.log
			 ################### Hostu açmazsan dashboard gelmez.
			 sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml	
			 echo "/etc/kibana/kibana.yml içerisinde server.host enable edilerek localhost yerine 0.0.0.0 olarak ayarlandı." >> /var/log/InstallInfo.log
        else
			 echo "2 girilen değer kibana değil."
        fi
        ###############Logstash area
        if [  "logstash" == "$listpack" ] ; then
					
			 echo "$listpack"" Paketi ""$ipaddress"" adressli bilgisayara kurulum başlatıldı." >> /var/log/InstallInfo.log
			 sudo apt install "$listpack" -y
					
			 touch /etc/logstash/conf.d/02-beats-input.conf
			 echo 'input {
						    beats {
								port => 5044
							}
						   }' >  /etc/logstash/conf.d/02-beats-input.conf
			 touch /etc/logstash/conf.d/30-elasticsearch-output.conf

			 echo "/etc/logstash/conf.d/02-beats-input.conf dosyasına port 5044 yönlendirmesi ayaralandı." >> /var/log/InstallInfo.log


			 echo 'output {
						  if [@metadata][pipeline] {
							elasticsearch {
							hosts => ["localhost:9200"]
							manage_template => false
							index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
							pipeline => "%{[@metadata][pipeline]}"
						  }
						  } else {
								elasticsearch {
								hosts => ["localhost:9200"]
								manage_template => false
								index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
								}
						    }
						  }'	   > /etc/logstash/conf.d/30-elasticsearch-output.conf

			 echo "/etc/logstash/conf.d/30-elasticsearch-output.conf içerisinde gelen verilerin %{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd} formatında parse edilme ve 9200 portuna yönlendirmesi yapıldı." >> /var/log/InstallInfo.log
						  
			 sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
			 echo "logstash --path.settings /etc/logstash olarak ayarlandı." >> /var/log/InstallInfo.log
			 sudo systemctl start logstash
			 sudo systemctl enable logstash
				    
        else
                echo "3 girilen değer logstash değil."
        fi
		 if [  "filebeat" == "$listpack" ] ; then
			 echo "$listpack"" Paketi ""$ipaddress"" adressli bilgisayara kurulum başlatıldı." >> /var/log/InstallInfo.log
			 sudo apt install "$listpack" -y
			 
			 sed -i 's/#output.elasticsearch:/output.elasticsearch:/g' /etc/filebeat/filebeat.yml
			 sed -i 's/#hosts: ["localhost:9200"]/hosts: ["localhost:5044"]/g' /etc/filebeat/filebeat.yml
			 sed -i 's/enabled: false/enabled: true/g' /etc/filebeat/filebeat.yml

			 echo "/etc/filebeat/filebeat.yml dosyası içerisinde output.elasticsearch: açıldı. " >> /var/log/InstallInfo.log
			 echo "/etc/filebeat/filebeat.yml dosyası içerisinde hosts: [localhost:5044] açıldı ve portu 9200 den 5044 olarak değiştirildi. " >> /var/log/InstallInfo.log
			 echo "/etc/filebeat/filebeat.yml dosyası içerisinde enabled: true olarak ayarlandı. " >> /var/log/InstallInfo.log
			  #filebeat.inputs:

					# Each - is an input. Most options can be set at the input level, so
					# you can use different inputs for various configurations.
					# Below are the input specific configurations.

					#		 filestream is an input for collecting log messages from files.
				#- input_type: log

  					# Change to true to enable this input configuration.
 					# enabled: true

 					 # Paths that should be crawled and fetched. Glob based paths.
  					#paths:
   					# - /var/log/*.log

			  
			 sudo filebeat modules enable system
			 sudo filebeat modules list
			  
			 sudo filebeat setup --pipelines --modules system
			 sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
			 echo "output.elasticsearch.hosts=[localhost:9200] olarak ayarlandı."  >> /var/log/InstallInfo.log
			 sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601
			 echo "setup.kibana.host=localhost:5601 olarak ayarlandı."  >> /var/log/InstallInfo.log
			  #http://localhost:5601/app/integrations/browse elasticsearh listede cıkmaz ise buradan bulup yükle.
			  
			 sudo systemctl start filebeat
			 sudo systemctl enable filebeat
			 echo "9200/filebeat-*/_search?pretty portuna get komutu yollanarak test edildi."  >> /var/log/InstallInfo.log
			 echo "##############################################" >> /var/log/InstallInfo.log
			 curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty' >> /var/log/InstallInfo.log
			 echo "##############################################" >> /var/log/InstallInfo.log
		 else
                echo "4 girilen değer filebeat değil."
        fi
        }


packagename "elasticsearch"
packagename "kibana"
packagename "logstash"
packagename "filebeat"
