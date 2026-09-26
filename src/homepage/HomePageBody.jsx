import Button from "../ux/Button";
import Slider from "../ux/Slider";
import { get, put, post, del } from "../api/crud";

function HomePageBody() {
  return (
    <div>
          <Button
            text="Onboard LED"
            onClickReference={onboardLedButton}
            style=
            {{
                minHeight: '100%',
                margin: '0 0 15px 0'
            }}
          />

          <Button
            text="Red LED"
            onClickReference={redLedButton}
            style=
            {{
                minHeight: '100%',
                margin: '0 0 15px 0'
            }}
          />

          <Slider
            style=
            {{
              minHeight: '100%',
                margin: '0 0 15px 0'
            }}
            onSlideReference={adjustLighting}/>

          <Button
            text="Yes"
            onClickReference={yes}
            style=
            {{
                minHeight: '100%',
                margin: '0 0 15px 0'
            }}
          />

          <Button
            text="No"
            onClickReference={no}
            style=
            {{
                minHeight: '100%',
                margin: '0 0 15px 0'
            }}
          />
    </div>
  );
}

function onboardLedButton()
{
  put('hardware/onBoardLed/power');
}

function redLedButton()
{
  put('hardware/redLed/power');
}

function yes()
{
  put('hardware/yesLed/power');
}

function no()
{
  put('hardware/noLed/power');
}

function adjustLighting(e)
{
  const lightValue = Number(e.target.value);
  const body = {light_percentage: lightValue, debounce_time: 5};
  var res = put('hardware/shelly/adjustLight', body);
}

export default HomePageBody;