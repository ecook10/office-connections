import React from "react"

function pctString(decimal) {
  return Math.round(decimal * 10000) / 100;
}

export default class GraphDetails extends React.Component {

  render() {
    var leadNodeProjectElements = [];
    this.props.leadNodeProjects.forEach(function(project) {
      leadNodeProjectElements.push(
          <tr key={ project.id }>
            <td>{ project.name }</td>
            <td>{ pctString(this.props.leadNodeProjectProportions[project.id]) + "%" }</td>
          </tr>
      );
    }.bind(this));

    return (
        <div className="graph-details">
          <h3>Projects Assigned to { this.props.leadNodeName }</h3>
          <table className="lead-projects"><tbody>
            { leadNodeProjectElements }
          </tbody></table>
          
          { this.props.selectedNodeName &&
            <h3>Details about graph node { this.props.selectedNodeName }</h3>
          }
        </div>
    )
  }
}
