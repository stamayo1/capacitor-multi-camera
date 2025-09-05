import { MultiCamera } from 'capacitor-multi-camera';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    MultiCamera.echo({ value: inputValue })
}
