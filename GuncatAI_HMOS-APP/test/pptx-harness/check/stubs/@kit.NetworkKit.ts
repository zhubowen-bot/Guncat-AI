export declare namespace http {
  enum RequestMethod { GET = 'GET', POST = 'POST' }
  enum HttpDataType { STRING = 0, ARRAY_BUFFER = 1 }
  interface HttpResponse { responseCode: number; result: Object; header: Object; }
  interface HttpRequest { request(url: string, options: object): Promise<HttpResponse>; destroy(): void; }
  function createHttp(): HttpRequest;
}
