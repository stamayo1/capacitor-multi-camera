import { Camera } from 'capacitor-multi-camera';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    Camera.echo({ value: inputValue })
}
