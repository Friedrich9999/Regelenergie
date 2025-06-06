import { React, useEffect } from "react";
import ReactLogo from './logo.svg';

const App = () => {
  useEffect(() => {})
  return (
    <div className="app">
      <h1>MovieLand</h1>
      <div className="search">
        <input 
        placeholder="Search" 
        value="superman"
        onChange={()=>{}}
        />
        <img src={ReactLogo}
        alt="search"
        onClick={()=>{}}
        />
        <div className="container">
          
        </div>
      </div>
    </div>
  );
}

export default App;