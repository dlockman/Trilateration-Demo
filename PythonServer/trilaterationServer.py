import json
import basicTrilateration
from numpy import *
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

class TrilaterationRequestHandler(BaseHTTPRequestHandler):
    point_data = {'B9407F30-F5F8-466E-AFF9-25556B57FE6D5362634111': array([.3, 0, 1]),
    'B9407F30-F5F8-466E-AFF9-25556B57FE6D2506132695': array([1.3, 4.2, 1]),
    'B9407F30-F5F8-466E-AFF9-25556B57FE6D4318862110': array([2.75, 0, 1])
    }
	
    def do_POST(self):
        print('Received post request!')
        content_len = int(self.headers.getheader('content-length'))
        post_body = self.rfile.read(content_len)
        print post_body
        postData = json.loads(post_body)

        identifiers = postData['identifiers']
        distance_data = postData['distances']

        point_estimate = basicTrilateration.trilaterateLM(self.point_data,distance_data,identifiers)

        #send code 200 response
        self.send_response(200)

        #send header first
        self.send_header('Content-type','json')
        self.end_headers()
        output = json.dumps({'point_estimate': point_estimate.tolist()})
        print output
        self.wfile.write(output)

def run():
	print('http server is starting...')

	#ip and port of servr
	#by default http server port is 80
	server_address = ('192.168.1.6', 9000)
	httpd = HTTPServer(server_address, TrilaterationRequestHandler)
	print('http server is running...')
	httpd.serve_forever()
    
if __name__ == '__main__':
    run()