import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App';
import {Portal} from './Portal';
import './style.css';
createRoot(document.getElementById('root')!).render(<StrictMode>{location.port==='5180'||new URLSearchParams(location.search).has('portal')?<Portal/>:<App/>}</StrictMode>);
