import {Streamdown} from 'streamdown';
import 'streamdown/styles.css';

const ocultos=['img','video','audio','iframe'];
export function ChatMarkdown({texto,generando=false}:{texto:string;generando?:boolean}){
 return <Streamdown className="chat-markdown" mode={generando?'streaming':'static'} isAnimating={generando}
  caret="block" controls={false} skipHtml disallowedElements={ocultos}>{texto}</Streamdown>;
}
